import Foundation
import Supabase
import Combine

@MainActor
class BaseRepository: ObservableObject {
    let client = SupabaseManager.shared.client
    
    var subscriptionTask: Task<Void, Never>?
    
    nonisolated internal var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    func stopObserving() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
        
        Task {
            await client.removeAllChannels()
        }
    }
}

@MainActor
class EventRepository: BaseRepository, EventRepositoryProtocol {
    
    func eventStream(since date: Date) -> AsyncThrowingStream<[Event], Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let events = try await fetchEventsFromServer(since: date)
                    continuation.yield(events)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        stopObserving()
        
        subscriptionTask = Task {
            do {
                let events = try await fetchEventsFromServer(since: Date())
                guard !Task.isCancelled else { return }
                completion(.success(events))
            } catch {
                guard !Task.isCancelled else { return }
                completion(.failure(error))
            }
        }
    }
    
    // UPDATED Implementation
        func fetchEventsFromServer(since date: Date, page: Int? = nil, pageSize: Int? = nil) async throws -> [Event] {
            let dateString = ISO8601DateFormatter().string(from: date)
            
            // 1. Start the query
            var query = client
                .from("events")
                .select()
                .gte("start_time", value: dateString)
            
            // 2. Apply pagination if parameters exist
            if let page = page, let pageSize = pageSize {
                // Supabase uses 0-based indexing for ranges
                // Page 1 (size 100) -> range(0, 99)
                let lowerBound = (page - 1) * pageSize
                let upperBound = lowerBound + pageSize - 1
                
                query = query.range(from: lowerBound, to: upperBound) as! PostgrestFilterBuilder
            }
            
            // 3. Execute
            let events: [Event] = try await query.execute().value
            
            return events
        }
    
    func fetchEvent(by id: String) async throws -> Event? {
        let event: Event = try await client
            .from("events")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return event
    }
    
    func fetchEvents(by ids: [String]) async throws -> [Event] {
        guard !ids.isEmpty else { return [] }
        
        let events: [Event] = try await client
            .from("events")
            .select()
            .in("id", values: ids)
            .execute()
            .value
        return events
    }
}

@MainActor
class TicketRepository: BaseRepository, TicketRepositoryProtocol {
    
    private var currentChannel: RealtimeChannelV2?
    private var cachedTickets: [Ticket] = []

    override func stopObserving() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
        
        if let channel = currentChannel {
            Task {
                await client.removeChannel(channel)
                currentChannel = nil
            }
        }
    }

    func observeUserTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void) {
        stopObserving()

        subscriptionTask = Task {
            // 1. Initial Fetch to populate cache
            do {
                try await self.initialFetchTickets(userId: userId)
                completion(.success(self.cachedTickets))
            } catch {
                completion(.failure(error))
                return
            }

            // 2. Set up Real-Time Subscription
            let channelName = "tickets-\(userId)-\(UUID().uuidString)"
            let channel = client.realtimeV2.channel(channelName)  // Removed await
            self.currentChannel = channel

            // 3. Set up streams with new filter syntax
            let insertStream = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "tickets",
                filter: .eq("user_id", value: userId)
            )
            let updateStream = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "tickets",
                filter: .eq("user_id", value: userId)
            )
            let deleteStream = channel.postgresChange(
                DeleteAction.self,
                schema: "public",
                table: "tickets",
                filter: .eq("user_id", value: userId)
            )

            // 4. Subscribe to channel using new method
            do {
                try await channel.subscribeWithError()
            } catch {
                completion(.failure(error))
                return
            }

            // 5. Handle payloads by MERGING into cachedTickets
            Task {
                await withThrowingTaskGroup(of: Void.self) { group in
                    
                    // HANDLE INSERT
                    group.addTask {
                        for await action in insertStream {
                            if let newTicket = try? action.decodeRecord(as: Ticket.self, decoder: self.decoder) {
                                await MainActor.run {
                                    self.cachedTickets.append(newTicket)
                                    self.cachedTickets.sort { $0.purchaseDate > $1.purchaseDate }
                                    let active = self.cachedTickets.filter { $0.status != "deleted" }
                                    completion(.success(active))
                                }
                            }
                        }
                    }
                    
                    // HANDLE UPDATE
                    group.addTask {
                        for await action in updateStream {
                            if let updatedTicket = try? action.decodeRecord(as: Ticket.self, decoder: self.decoder) {
                                await MainActor.run {
                                    if let index = self.cachedTickets.firstIndex(where: { $0.id == updatedTicket.id }) {
                                        self.cachedTickets[index] = updatedTicket
                                    } else {
                                        self.cachedTickets.append(updatedTicket)
                                        self.cachedTickets.sort { $0.purchaseDate > $1.purchaseDate }
                                    }
                                    let active = self.cachedTickets.filter { $0.status != "deleted" }
                                    completion(.success(active))
                                }
                            }
                        }
                    }

                    // HANDLE DELETE
                    group.addTask {
                        for await action in deleteStream {
                            // Fixed: oldRecord is already [String: AnyJSON], no cast needed
                            if let deletedId = action.oldRecord["id"]?.stringValue {
                                await MainActor.run {
                                    self.cachedTickets.removeAll { $0.id == deletedId }
                                    let active = self.cachedTickets.filter { $0.status != "deleted" }
                                    completion(.success(active))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func initialFetchTickets(userId: String) async throws {
        let tickets: [Ticket] = try await client
            .from("tickets")
            .select()
            .eq("user_id", value: userId.lowercased())
            .order("purchase_date", ascending: false)
            .execute()
            .value
        
        self.cachedTickets = tickets
    }
    
    func userHasTicket(userId: String, eventId: String) async throws -> Bool {
        let count = try await client
            .from("tickets")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("event_id", value: eventId)
            .eq("status", value: "confirmed")
            .execute()
            .count
        
        return (count ?? 0) > 0
    }
    
    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool] {
        guard !eventIds.isEmpty else { return [:] }
        
        var status: [String: Bool] = [:]
        for eventId in eventIds { status[eventId] = false }
        
        let tickets: [Ticket] = try await client
            .from("tickets")
            .select()
            .eq("user_id", value: userId)
            .in("event_id", values: eventIds)
            .eq("status", value: "confirmed")
            .execute()
            .value
        
        for ticket in tickets {
            status[ticket.eventId] = true
        }
        
        return status
    }
}

struct BookmarkData: Identifiable, Codable, Sendable {
    var id: String?
    let eventId: String
    let eventName: String
    let venue: String
    let startTime: Date
    let eventPrice: Double
    let eventImageUrl: String
    let bookmarkedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case eventName = "event_name"
        case venue
        case startTime = "start_time"
        case eventPrice = "event_price"
        case eventImageUrl = "event_image_url"
        case bookmarkedAt = "bookmarked_at"
    }
}

@MainActor
class BookmarkRepository: BaseRepository, BookmarkRepositoryProtocol {
    
    private var currentChannel: RealtimeChannelV2?
    private var cachedBookmarks: [BookmarkData] = []
    
    override func stopObserving() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
        
        if let channel = currentChannel {
            Task {
                await client.removeChannel(channel)
                currentChannel = nil
            }
        }
    }
    
    func observeBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void) {
        stopObserving()
        
        subscriptionTask = Task {
            do {
                try await self.initialFetchBookmarks(userId: userId)
                completion(.success(self.cachedBookmarks))
            } catch {
                completion(.failure(error))
                return
            }
            
            let channelName = "bookmarks-\(userId)-\(UUID().uuidString)"
            let channel = client.realtimeV2.channel(channelName)  // Removed await
            currentChannel = channel
            
            // Use new filter syntax
            let insertStream = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "bookmarks",
                filter: .eq("user_id", value: userId)
            )
            let updateStream = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "bookmarks",
                filter: .eq("user_id", value: userId)
            )
            let deleteStream = channel.postgresChange(
                DeleteAction.self,
                schema: "public",
                table: "bookmarks",
                filter: .eq("user_id", value: userId)
            )
            
            // Use new subscribe method
            do {
                try await channel.subscribeWithError()
            } catch {
                completion(.failure(error))
                return
            }
            
            Task {
                await withThrowingTaskGroup(of: Void.self) { group in
                    
                    group.addTask {
                        for await action in insertStream {
                            if let newBookmark = try? action.decodeRecord(as: BookmarkData.self, decoder: self.decoder) {
                                await MainActor.run {
                                    self.cachedBookmarks.append(newBookmark)
                                    completion(.success(self.cachedBookmarks))
                                }
                            }
                        }
                    }
                    
                    group.addTask {
                        for await action in updateStream {
                            if let updatedBookmark = try? action.decodeRecord(as: BookmarkData.self, decoder: self.decoder) {
                                await MainActor.run {
                                    if let index = self.cachedBookmarks.firstIndex(where: { $0.id == updatedBookmark.id }) {
                                        self.cachedBookmarks[index] = updatedBookmark
                                    } else {
                                        self.cachedBookmarks.append(updatedBookmark)
                                    }
                                    completion(.success(self.cachedBookmarks))
                                }
                            }
                        }
                    }
                    
                    group.addTask {
                        for await action in deleteStream {
                            // Fixed: use AnyJSON's stringValue property
                            if let deletedId = action.oldRecord["id"]?.stringValue {
                                await MainActor.run {
                                    self.cachedBookmarks.removeAll { $0.id == deletedId }
                                    completion(.success(self.cachedBookmarks))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func initialFetchBookmarks(userId: String) async throws {
        let bookmarks: [BookmarkData] = try await client
            .from("bookmarks")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        self.cachedBookmarks = bookmarks
    }
    
    func addBookmark(userId: String, bookmark: BookmarkData) async throws {
        struct BookmarkInsert: Encodable {
            let userId: String
            let eventId: String
            let eventName: String
            let venue: String
            let startTime: Date
            let eventPrice: Double
            let eventImageUrl: String
            let bookmarkedAt: Date
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case eventId = "event_id"
                case eventName = "event_name"
                case venue
                case startTime = "start_time"
                case eventPrice = "event_price"
                case eventImageUrl = "event_image_url"
                case bookmarkedAt = "bookmarked_at"
            }
        }
        
        let insertData = BookmarkInsert(
            userId: userId,
            eventId: bookmark.eventId,
            eventName: bookmark.eventName,
            venue: bookmark.venue,
            startTime: bookmark.startTime,
            eventPrice: bookmark.eventPrice,
            eventImageUrl: bookmark.eventImageUrl,
            bookmarkedAt: bookmark.bookmarkedAt
        )
        
        try await client
            .from("bookmarks")
            .insert(insertData)
            .execute()
    }
    
    func removeBookmark(userId: String, eventId: String) async throws {
        try await client
            .from("bookmarks")
            .delete()
            .eq("user_id", value: userId)
            .eq("event_id", value: eventId)
            .execute()
    }
}

@MainActor
class UserRepository: BaseRepository, UserRepositoryProtocol {
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        do {
            // First check if user exists
            let profiles: [UserProfile] = try await client
                .from("users")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            // Return first match or nil
            return profiles.first
        } catch {
            print("⚠️ Error fetching user profile: \(error)")
            return nil
        }
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        var dbData: [String: Any] = [:]
        for (key, value) in data {
            let snakeKey = convertToSnakeCase(key)
            dbData[snakeKey] = value
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: dbData)
        let json = try JSONDecoder().decode(AnyJSON.self, from: jsonData)
        
        try await client
            .from("users")
            .update(json)
            .eq("id", value: userId)
            .execute()
    }
    
    func createUserProfile(userId: String, profile: UserProfile) async throws {
        try await client
            .from("users")
            .upsert(profile)
            .execute()
    }
    
    func userExists(userId: String) async throws -> Bool {
        let count = try await client
            .from("users")
            .select("*", head: true, count: .exact)
            .eq("id", value: userId)
            .execute()
            .count
        return (count ?? 0) > 0
    }
    
    private func convertToSnakeCase(_ input: String) -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: input.utf16.count)
        let snakeCase = regex?.stringByReplacingMatches(
            in: input,
            options: [],
            range: range,
            withTemplate: "$1_$2"
        )
        return snakeCase?.lowercased() ?? input
    }
}

struct UserProfile: Codable, Sendable {
    var id: String?
    var email: String
    var displayName: String?
    var role: String
    var provider: String
    var venuePermissions: [String]
    var createdAt: Date?
    var lastLoginAt: Date?
    var phoneNumber: String?
    var stripeCustomerId: String?
    var profileImageUrl: String?
    var preferences: UserPreferences?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case role
        case provider
        case venuePermissions = "venue_permissions"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
        case phoneNumber = "phone_number"
        case stripeCustomerId = "stripe_customer_id"
        case profileImageUrl = "profile_image_url"
        case preferences
    }
    
    // MARK: - FIX: Explicit Memberwise Initializer added
    init(id: String? = nil, email: String, displayName: String? = nil, role: String, provider: String, venuePermissions: [String], createdAt: Date? = nil, lastLoginAt: Date? = nil, phoneNumber: String? = nil, stripeCustomerId: String? = nil, profileImageUrl: String? = nil, preferences: UserPreferences? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.provider = provider
        self.venuePermissions = venuePermissions
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.phoneNumber = phoneNumber
        self.stripeCustomerId = stripeCustomerId
        self.profileImageUrl = profileImageUrl
        self.preferences = preferences
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        role = try container.decode(String.self, forKey: .role)
        provider = try container.decode(String.self, forKey: .provider)
        
        // Handle venue_permissions - it might be a string "[]" or an array
        if let permissionsArray = try? container.decode([String].self, forKey: .venuePermissions) {
            venuePermissions = permissionsArray
        } else if let permissionsString = try? container.decode(String.self, forKey: .venuePermissions) {
            // Parse "[]" string to empty array
            if let data = permissionsString.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                venuePermissions = array
            } else {
                venuePermissions = []
            }
        } else {
            venuePermissions = []
        }
        
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        lastLoginAt = try container.decodeIfPresent(Date.self, forKey: .lastLoginAt)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        stripeCustomerId = try container.decodeIfPresent(String.self, forKey: .stripeCustomerId)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        preferences = try container.decodeIfPresent(UserPreferences.self, forKey: .preferences)
    }
}

struct UserPreferences: Codable, Sendable {
    var notifications: Bool
    var emailMarketing: Bool
    var pushNotifications: Bool
    
    init(notifications: Bool = true, emailMarketing: Bool = false, pushNotifications: Bool = true) {
        self.notifications = notifications
        self.emailMarketing = emailMarketing
        self.pushNotifications = pushNotifications
    }
}
