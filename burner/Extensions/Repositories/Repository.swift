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
        eventsListener = db.collection("events")
            .order(by: "startTime", descending: false)
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
    
    // MARK: - Fetch User Ticket Status for Multiple Events
    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool] {
        let snapshot = try await db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments()
        
        let eventIdsWithTickets = Set(snapshot.documents.compactMap { doc -> String? in
            doc.data()["eventId"] as? String
        })
        
        var status: [String: Bool] = [:]
        for eventId in eventIds {
            status[eventId] = eventIdsWithTickets.contains(eventId)
        }
        return status
    }
    
    // MARK: - Stop Observing
    func stopObserving() {
        ticketsListener?.remove()
        ticketsListener = nil
    }
}

// MARK: - BookmarkData Model (moved here so it's accessible)
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
        let eventId = bookmark.eventId  // ✅ Changed from bookmark.id to bookmark.eventId
        
        try db.collection("users")
            .document(userId)
            .collection("bookmarks")
            .document(eventId)  // Use eventId as the document ID
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
    
    // NEW: Additional fields from Phase 4
    var phoneNumber: String?
    var stripeCustomerId: String?
    var profileImageUrl: String?
    var preferences: UserPreferences?
}

// NEW: Preferences struct
struct UserPreferences: Codable, Sendable {
    var notifications: Bool
    var emailMarketing: Bool
    var pushNotifications: Bool
    
    // Default values
    init(notifications: Bool = true, emailMarketing: Bool = false, pushNotifications: Bool = true) {
        self.notifications = notifications
        self.emailMarketing = emailMarketing
        self.pushNotifications = pushNotifications
    }
}

