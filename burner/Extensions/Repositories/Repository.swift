import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Repository Protocol
protocol Repository {
    associatedtype T
    func fetch() async throws -> [T]
    func fetchById(_ id: String) async throws -> T?
}

// MARK: - Event Repository
@MainActor
class EventRepository: ObservableObject {
    private let db = Firestore.firestore()
    private var eventsListener: ListenerRegistration?
    
    deinit {
        eventsListener?.remove()
    }
    
    // MARK: - Fetch Events with Real-time Updates
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        eventsListener?.remove()
        
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        eventsListener = db.collection("events")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: sevenDaysAgo))
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let events = documents.compactMap { doc -> Event? in
                    var event = try? doc.data(as: Event.self)
                    event?.id = doc.documentID
                    return event
                }

                completion(.success(events))
            }
    }
    
    // MARK: - Fetch Single Event
    func fetchEvent(by id: String) async throws -> Event? {
        let document = try await db.collection("events").document(id).getDocument()
        var event = try? document.data(as: Event.self)
        event?.id = document.documentID
        return event
    }

    // MARK: - Fetch Multiple Events (Batch with whereIn)
    func fetchEvents(by ids: [String]) async throws -> [Event] {
        guard !ids.isEmpty else { return [] }

        guard ids.count <= 10 else {
            throw NSError(domain: "EventRepository", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Cannot fetch more than 10 events at once with whereIn"
            ])
        }

        let snapshot = try await db.collection("events")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Event? in
            var event = try? doc.data(as: Event.self)
            event?.id = doc.documentID
            return event
        }
    }

    // MARK: - Stop Observing
    func stopObserving() {
        eventsListener?.remove()
        eventsListener = nil
    }
}

// MARK: - Ticket Repository
@MainActor
class TicketRepository: ObservableObject {
    private let db = Firestore.firestore()
    private var ticketsListener: ListenerRegistration?
    
    deinit {
        ticketsListener?.remove()
    }
    
    // MARK: - Observe User Tickets
    func observeUserTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void) {
        ticketsListener?.remove()
        
        ticketsListener = db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .order(by: "purchaseDate", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let tickets = documents.compactMap { doc -> Ticket? in
                    var ticket = try? doc.data(as: Ticket.self)
                    ticket?.id = doc.documentID
                    if ticket?.status == "deleted" {
                        return nil
                    }
                    return ticket
                }

                completion(.success(tickets))
            }
    }
    
    // MARK: - Check if User Has Ticket
    func userHasTicket(userId: String, eventId: String) async throws -> Bool {
        let snapshot = try await db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .whereField("eventId", isEqualTo: eventId)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Fetch User Ticket Status for Multiple Events (Optimized with whereIn Batching)
    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool] {
        guard !eventIds.isEmpty else { return [:] }

        var status: [String: Bool] = [:]

        for eventId in eventIds {
            status[eventId] = false
        }

        let batchSize = 10
        let batches = stride(from: 0, to: eventIds.count, by: batchSize).map {
            Array(eventIds[$0..<min($0 + batchSize, eventIds.count)])
        }

        for batch in batches {
            let snapshot = try await db.collection("tickets")
                .whereField("userId", isEqualTo: userId)
                .whereField("eventId", in: batch)
                .whereField("status", isEqualTo: "confirmed")
                .getDocuments()

            let eventIdsWithTickets = Set(snapshot.documents.compactMap { doc -> String? in
                doc.data()["eventId"] as? String
            })

            for eventId in batch {
                if eventIdsWithTickets.contains(eventId) {
                    status[eventId] = true
                }
            }
        }

        return status
    }

    // MARK: - Stop Observing
    func stopObserving() {
        ticketsListener?.remove()
        ticketsListener = nil
    }
}

// MARK: - BookmarkData Model
struct BookmarkData: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    let eventId: String
    let eventName: String
    let eventVenue: String
    let startTime: Date
    let eventPrice: Double
    let eventImageUrl: String
    let bookmarkedAt: Date
}

// MARK: - Bookmark Repository
@MainActor
class BookmarkRepository: ObservableObject {
    private let db = Firestore.firestore()
    private var bookmarksListener: ListenerRegistration?
    
    deinit {
        bookmarksListener?.remove()
    }
    
    // MARK: - Observe Bookmarks
    func observeBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void) {
        bookmarksListener?.remove()
        
        bookmarksListener = db.collection("users")
            .document(userId)
            .collection("bookmarks")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let bookmarks = documents.compactMap { doc in
                    try? doc.data(as: BookmarkData.self)
                }
                
                completion(.success(bookmarks))
            }
    }
    
    // MARK: - Add Bookmark
    func addBookmark(userId: String, bookmark: BookmarkData) async throws {
        let eventId = bookmark.eventId
        
        try db.collection("users")
            .document(userId)
            .collection("bookmarks")
            .document(eventId)
            .setData(from: bookmark)
    }
    
    // MARK: - Remove Bookmark
    func removeBookmark(userId: String, eventId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("bookmarks")
            .document(eventId)
            .delete()
    }
    
    // MARK: - Stop Observing
    func stopObserving() {
        bookmarksListener?.remove()
        bookmarksListener = nil
    }
}

// MARK: - User Repository
@MainActor
class UserRepository: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let document = try await db.collection("users").document(userId).getDocument()
        return try? document.data(as: UserProfile.self)
    }
    
    // MARK: - Update User Profile
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }
    
    // MARK: - Create User Profile
    func createUserProfile(userId: String, profile: UserProfile) async throws {
        try db.collection("users").document(userId).setData(from: profile)
    }
    
    // MARK: - Check if User Exists
    func userExists(userId: String) async throws -> Bool {
        let document = try await db.collection("users").document(userId).getDocument()
        return document.exists
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable, Sendable {
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

// MARK: - Preferences struct
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
