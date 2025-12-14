import Foundation
import Supabase
import Combine

@MainActor
class BaseRepository: ObservableObject {
    let client = SupabaseManager.shared.client
    
    // Track the active subscription task so it can be cancelled
    var subscriptionTask: Task<Void, Never>?

    func stopObserving() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
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
            
            // Allow stream cancellation to cancel the task
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
            .in("id", value: ids)
            .execute()
            .value
        return events
    }
}

@MainActor
class TicketRepository: BaseRepository, TicketRepositoryProtocol {

    func observeUserTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void) {
        stopObserving()
        
        subscriptionTask = Task {
            do {
                let tickets: [Ticket] = try await client
                    .from("tickets")
                    .select()
                    .eq("userId", value: userId)
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
            .in("eventId", value: eventIds)
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
    let eventVenue: String
    let startTime: Date
    let eventPrice: Double
    let eventImageUrl: String
    let bookmarkedAt: Date
}

@MainActor
class BookmarkRepository: BaseRepository, BookmarkRepositoryProtocol {

    func observeBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void) {
        stopObserving()
        
        subscriptionTask = Task {
            do {
                let bookmarks: [BookmarkData] = try await client
                    .from("bookmarks")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                guard !Task.isCancelled else { return }
                completion(.success(bookmarks))
            } catch {
                guard !Task.isCancelled else { return }
                completion(.failure(error))
            }
        }
    }

    func addBookmark(userId: String, bookmark: BookmarkData) async throws {
        struct BookmarkInsert: Encodable {
            let user_id: String
            let eventId: String
            let eventName: String
            let eventVenue: String
            let startTime: Date
            let eventPrice: Double
            let eventImageUrl: String
            let bookmarkedAt: Date
        }
        
        let insertData = BookmarkInsert(
            user_id: userId,
            eventId: bookmark.eventId,
            eventName: bookmark.eventName,
            eventVenue: bookmark.eventVenue,
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
            .eq("eventId", value: eventId)
            .execute()
    }
}

@MainActor
class UserRepository: BaseRepository, UserRepositoryProtocol {

    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        do {
            let profile: UserProfile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            return profile
        } catch {
            return nil
        }
    }

    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let json = try JSONDecoder().decode(AnyJSON.self, from: jsonData)
        
        try await client
            .from("profiles")
            .update(json)
            .eq("id", value: userId)
            .execute()
    }

    func createUserProfile(userId: String, profile: UserProfile) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }

    func userExists(userId: String) async throws -> Bool {
        let count = try await client
            .from("profiles")
            .select("*", head: true, count: .exact)
            .eq("id", value: userId)
            .execute()
            .count
        return (count ?? 0) > 0
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
