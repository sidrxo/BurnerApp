import Foundation
import Supabase
import Combine

@MainActor
class BaseRepository: ObservableObject {
    let client = SupabaseManager.shared.client
    
    var subscriptionTask: Task<Void, Never>?
    
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
        
        func fetchEventsFromServer(since date: Date) async throws -> [Event] {
            let dateString = ISO8601DateFormatter().string(from: date)
            
            let events: [Event] = try await client
                .from("events")
                .select()
                .gte("startTime", value: dateString)
                .execute()
                .value
            
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
                // 1. Initial Fetch
                await self.refetchTickets(userId: userId, completion: completion)

                // 2. Set up Real-Time Subscription
                let channelName = "tickets-\(userId)-\(UUID().uuidString)"
                let channel = await client.realtimeV2.channel(channelName)
                self.currentChannel = channel

                // Column name is 'userId' (camelCase)
                let filter = "userId=eq.\(userId)"
                
                // Set up streams for all changes
                let insertStream = await channel.postgresChange(InsertAction.self, schema: "public", table: "tickets", filter: filter)
                let updateStream = await channel.postgresChange(UpdateAction.self, schema: "public", table: "tickets", filter: filter)
                let deleteStream = await channel.postgresChange(DeleteAction.self, schema: "public", table: "tickets", filter: filter)

                // Subscribe to the channel
                await channel.subscribe()

                // 3. FIX: Handle changes by merging streams with a concurrent Task Group
                Task {
                    await withThrowingTaskGroup(of: Void.self) { group in
                        
                        // Add tasks for each stream
                        group.addTask {
                            for await _ in insertStream {
                                await self.refetchTickets(userId: userId, completion: completion)
                            }
                        }
                        
                        group.addTask {
                            for await _ in updateStream {
                                await self.refetchTickets(userId: userId, completion: completion)
                            }
                        }

                        group.addTask {
                            for await _ in deleteStream {
                                await self.refetchTickets(userId: userId, completion: completion)
                            }
                        }
                    }
                }
            }
        }
        
        private func refetchTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void) async {
            do {
                let tickets: [Ticket] = try await client
                    .from("tickets")
                    .select()
                    .eq("userId", value: userId.lowercased())
                    .order("purchaseDate", ascending: false)
                    .execute()
                    .value
                
                guard !Task.isCancelled else { return }
                let activeTickets = tickets.filter { $0.status != "deleted" }
                completion(.success(activeTickets))
            } catch {
                guard !Task.isCancelled else { return }
                completion(.failure(error))
            }
        }
        
        func userHasTicket(userId: String, eventId: String) async throws -> Bool {
            let count = try await client
                .from("tickets")
                .select("*", head: true, count: .exact)
                .eq("userId", value: userId)
                .eq("eventId", value: eventId)
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
                .eq("userId", value: userId)
                .in("eventId", values: eventIds)
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
        
        // FIXED: No CodingKeys needed - database uses camelCase!
    }
    
    @MainActor
    class BookmarkRepository: BaseRepository, BookmarkRepositoryProtocol {
        
        private var currentChannel: RealtimeChannelV2?
        
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
                // Initial fetch
                await self.refetchBookmarks(userId: userId, completion: completion)
                
                // Set up realtime subscription
                let channelName = "bookmarks-\(userId)-\(UUID().uuidString)"
                let channel = await client.realtimeV2.channel(channelName)
                currentChannel = channel
                
                // Listen to all changes on the bookmarks table for this user
                let insertStream = await channel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "bookmarks",
                    filter: "userId=eq.\(userId)"
                )
                
                let updateStream = await channel.postgresChange(
                    UpdateAction.self,
                    schema: "public",
                    table: "bookmarks",
                    filter: "userId=eq.\(userId)"
                )
                
                let deleteStream = await channel.postgresChange(
                    DeleteAction.self,
                    schema: "public",
                    table: "bookmarks",
                    filter: "userId=eq.\(userId)"
                )
                
                // Subscribe to the channel
                await channel.subscribe()
                
                // Handle change events
                Task {
                    await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask { for await _ in insertStream { await self.refetchBookmarks(userId: userId, completion: completion) } }
                        group.addTask { for await _ in updateStream { await self.refetchBookmarks(userId: userId, completion: completion) } }
                        group.addTask { for await _ in deleteStream { await self.refetchBookmarks(userId: userId, completion: completion) } }
                    }
                }
            }
        }
        
        private func refetchBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void) async {
            do {
                let bookmarks: [BookmarkData] = try await client
                    .from("bookmarks")
                    .select()
                    .eq("userId", value: userId)
                    .execute()
                    .value
                
                guard !Task.isCancelled else { return }
                completion(.success(bookmarks))
            } catch {
                guard !Task.isCancelled else { return }
                completion(.failure(error))
            }
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
                .eq("userId", value: userId)
                .eq("eventId", value: eventId)
                .execute()
        }
    }
    
    @MainActor
    class UserRepository: BaseRepository, UserRepositoryProtocol {
        
        func fetchUserProfile(userId: String) async throws -> UserProfile? {
            do {
                let profile: UserProfile = try await client
                    .from("users")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                return profile
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
        var displayName: String
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
