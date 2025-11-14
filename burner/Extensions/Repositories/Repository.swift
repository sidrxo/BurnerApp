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
        // Remove existing listener first to prevent duplicates
        eventsListener?.remove()

        print("🔥 [EventRepository] Setting up events listener...")

        // Calculate date for filtering (7 days ago to include recent past events)
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        // ✅ OPTIMIZED: Add server-side filtering to reduce data transfer
        // Fetch events with startTime >= 7 days ago OR featured events (startTime may be nil)
        // This significantly reduces the amount of data fetched from Firestore
        eventsListener = db.collection("events")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: sevenDaysAgo))
            .addSnapshotListener { snapshot, error in
                print("🔥 [EventRepository] Snapshot listener triggered")

                if let error = error {
                    print("❌ [EventRepository] Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ [EventRepository] No documents found")
                    completion(.success([]))
                    return
                }

                print("✅ [EventRepository] Received \(documents.count) events (filtered server-side)")

                let events = documents.compactMap { doc -> Event? in
                    var event = try? doc.data(as: Event.self)
                    event?.id = doc.documentID
                    return event
                }

                print("✅ [EventRepository] Parsed \(events.count) events successfully")
                completion(.success(events))
            }

        // Also fetch featured events separately (they might have nil startTime)
        // This ensures featured events are not missed by the date filter
        db.collection("events")
            .whereField("isFeatured", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("⚠️ [EventRepository] Featured events fetch error: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let featuredEvents = documents.compactMap { doc -> Event? in
                    var event = try? doc.data(as: Event.self)
                    event?.id = doc.documentID
                    return event
                }

                if !featuredEvents.isEmpty {
                    print("✅ [EventRepository] Fetched \(featuredEvents.count) featured events")
                    completion(.success(featuredEvents))
                }
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

        // Firestore whereIn supports max 10 values
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
        print("🛑 [EventRepository] Stopping events listener")
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
        // Remove existing listener first to prevent duplicates
        ticketsListener?.remove()
        
        print("🎫 [TicketRepository] Setting up tickets listener for user: \(userId)")
        
        ticketsListener = db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .order(by: "purchaseDate", descending: true)
            .addSnapshotListener { snapshot, error in
                print("🎫 [TicketRepository] Snapshot listener triggered")
                
                if let error = error {
                    print("❌ [TicketRepository] Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ [TicketRepository] No documents found")
                    completion(.success([]))
                    return
                }
                
                print("✅ [TicketRepository] Received \(documents.count) tickets")
                
                let tickets = documents.compactMap { doc -> Ticket? in
                    var ticket = try? doc.data(as: Ticket.self)
                    ticket?.id = doc.documentID
                    // Filter out deleted tickets
                    if ticket?.status == "deleted" {
                        return nil
                    }
                    return ticket
                }

                print("✅ [TicketRepository] Parsed \(tickets.count) valid tickets")
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

        // Initialize all as false
        for eventId in eventIds {
            status[eventId] = false
        }

        // Split into batches of 10 (Firestore whereIn limit)
        let batchSize = 10
        let batches = stride(from: 0, to: eventIds.count, by: batchSize).map {
            Array(eventIds[$0..<min($0 + batchSize, eventIds.count)])
        }

        // Fetch each batch and merge results
        for batch in batches {
            let snapshot = try await db.collection("tickets")
                .whereField("userId", isEqualTo: userId)
                .whereField("eventId", in: batch)
                .whereField("status", isEqualTo: "confirmed")
                .getDocuments()

            let eventIdsWithTickets = Set(snapshot.documents.compactMap { doc -> String? in
                doc.data()["eventId"] as? String
            })

            // Update status for this batch
            for eventId in batch {
                if eventIdsWithTickets.contains(eventId) {
                    status[eventId] = true
                }
            }
        }

        return status
    }
    
    // MARK: - Delete Ticket (Soft Delete)
    func deleteTicket(ticketId: String) async throws {
        try await db.collection("tickets").document(ticketId).updateData([
            "status": "deleted",
            "deletedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Stop Observing
    func stopObserving() {
        print("🛑 [TicketRepository] Stopping tickets listener")
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
        // Remove existing listener first to prevent duplicates
        bookmarksListener?.remove()
        
        print("🔖 [BookmarkRepository] Setting up bookmarks listener for user: \(userId)")
        
        bookmarksListener = db.collection("users")
            .document(userId)
            .collection("bookmarks")
            .addSnapshotListener { snapshot, error in
                print("🔖 [BookmarkRepository] Snapshot listener triggered")
                
                if let error = error {
                    print("❌ [BookmarkRepository] Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ [BookmarkRepository] No documents found")
                    completion(.success([]))
                    return
                }
                
                print("✅ [BookmarkRepository] Received \(documents.count) bookmarks")
                
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
        print("🛑 [BookmarkRepository] Stopping bookmarks listener")
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
