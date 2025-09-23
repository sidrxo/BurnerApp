//
//  BookmarkManager.swift
//  burner
//
//  Created by Sid Rao on 23/09/2025.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarkedEvents: [Event] = []
    @Published var bookmarkStatus: [String: Bool] = [:]
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var bookmarkListener: ListenerRegistration?
    
    init() {
        setupBookmarkListener()
    }
    
    deinit {
        bookmarkListener?.remove()
    }
    
    // MARK: - Setup Listener
    private func setupBookmarkListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        bookmarkListener = db.collection("users")
            .document(userId)
            .collection("bookmarks")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Error fetching bookmarks: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.bookmarkedEvents = []
                        self.bookmarkStatus = [:]
                        return
                    }
                    
                    let bookmarks = documents.compactMap { doc in
                        try? doc.data(as: BookmarkData.self)
                    }
                    
                    // Update bookmark status dictionary
                    var newStatus: [String: Bool] = [:]
                    for bookmark in bookmarks {
                        newStatus[bookmark.eventId] = true
                    }
                    self.bookmarkStatus = newStatus
                    
                    // Fetch full event details
                    await self.fetchBookmarkedEvents(bookmarks: bookmarks)
                }
            }
    }
    
    // MARK: - Fetch Bookmarked Events
    private func fetchBookmarkedEvents(bookmarks: [BookmarkData]) async {
        let eventIds = bookmarks.map { $0.eventId }
        
        guard !eventIds.isEmpty else {
            bookmarkedEvents = []
            return
        }
        
        do {
            let eventsSnapshot = try await db.collection("events")
                .whereField(FieldPath.documentID(), in: eventIds)
                .getDocuments()
            
            let events = eventsSnapshot.documents.compactMap { doc -> Event? in
                var event = try? doc.data(as: Event.self)
                event?.id = doc.documentID
                return event
            }
            
            // Sort by bookmark date (most recent first)
            let sortedEvents = events.sorted { event1, event2 in
                let bookmark1 = bookmarks.first { $0.eventId == event1.id }
                let bookmark2 = bookmarks.first { $0.eventId == event2.id }
                
                guard let date1 = bookmark1?.bookmarkedAt,
                      let date2 = bookmark2?.bookmarkedAt else {
                    return false
                }
                
                return date1 > date2
            }
            
            bookmarkedEvents = sortedEvents
        } catch {
            print("❌ Error fetching bookmarked events: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Bookmark Actions
    func toggleBookmark(for event: Event) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let eventId = event.id else {
            print("❌ User not authenticated or invalid event ID")
            return
        }
        
        let isCurrentlyBookmarked = bookmarkStatus[eventId] ?? false
        
        if isCurrentlyBookmarked {
            await removeBookmark(userId: userId, eventId: eventId)
        } else {
            await addBookmark(userId: userId, event: event)
        }
    }
    
    private func addBookmark(userId: String, event: Event) async {
        guard let eventId = event.id else { return }
        
        let bookmark = BookmarkData(
            eventId: eventId,
            eventName: event.name,
            eventVenue: event.venue,
            eventDate: event.date,
            eventPrice: event.price,
            eventImageUrl: event.imageUrl,
            bookmarkedAt: Date()
        )
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("bookmarks")
                .document(eventId)
                .setData(from: bookmark)
            
            print("✅ Bookmark added successfully")
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            print("❌ Error adding bookmark: \(error.localizedDescription)")
        }
    }
    
    private func removeBookmark(userId: String, eventId: String) async {
        do {
            try await db.collection("users")
                .document(userId)
                .collection("bookmarks")
                .document(eventId)
                .delete()
            
            print("✅ Bookmark removed successfully")
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            print("❌ Error removing bookmark: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    func isBookmarked(_ eventId: String) -> Bool {
        return bookmarkStatus[eventId] ?? false
    }
    
    func clearBookmarks() {
        bookmarkedEvents = []
        bookmarkStatus = [:]
        bookmarkListener?.remove()
        bookmarkListener = nil
    }
}

// MARK: - BookmarkData Model
struct BookmarkData: Identifiable, Codable {
    @DocumentID var id: String?
    let eventId: String
    let eventName: String
    let eventVenue: String
    let eventDate: Date
    let eventPrice: Double
    let eventImageUrl: String
    let bookmarkedAt: Date
}