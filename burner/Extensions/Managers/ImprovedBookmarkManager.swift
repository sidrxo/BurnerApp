import Swift
import Combine
import Supabase
import UIKit

// IMPROVED: BookmarkManager without realtime subscriptions
@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarkedEvents: [Event] = []
    @Published var bookmarkStatus: [String: Bool] = [:]
    @Published var isLoading = false
    @Published var isTogglingBookmark: [String: Bool] = [:]
    @Published var bookmarkError: BookmarkError?

    private let bookmarkRepository: BookmarkRepository
    private let eventRepository: EventRepository

    struct BookmarkError: Identifiable {
        let id = UUID()
        let eventId: String
        let eventName: String
        let message: String
    }

    init(
        bookmarkRepository: BookmarkRepository,
        eventRepository: EventRepository
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.eventRepository = eventRepository

        // Load bookmarks once on init
        Task {
            await loadBookmarks()
        }
    }

    // MARK: - Load Bookmarks (called on app launch + pull-to-refresh)
    func loadBookmarks() async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else {
            return
        }

        isLoading = true

        do {
            // 1. Fetch bookmark records
            let bookmarks = try await bookmarkRepository.fetchBookmarks(userId: userId)

            // 2. Update status dictionary
            var newStatus: [String: Bool] = [:]
            for bookmark in bookmarks {
                newStatus[bookmark.eventId] = true
            }
            bookmarkStatus = newStatus

            // 3. Fetch full event details in parallel
            await fetchBookmarkedEvents(bookmarks: bookmarks)

        } catch {
            // Handle error silently or show to user
        }

        isLoading = false
    }

    // MARK: - Fetch Event Details (parallel batching)
    private func fetchBookmarkedEvents(bookmarks: [BookmarkData]) async {
        let eventIds = bookmarks.map { $0.eventId }

        guard !eventIds.isEmpty else {
            bookmarkedEvents = []
            return
        }

        // Fetch events in parallel batches of 10
        let batchSize = 10
        let batches = stride(from: 0, to: eventIds.count, by: batchSize).map {
            Array(eventIds[$0..<min($0 + batchSize, eventIds.count)])
        }

        do {
            let events = try await withThrowingTaskGroup(of: [Event].self) { group in
                for batch in batches {
                    group.addTask {
                        try await self.eventRepository.fetchEvents(by: batch)
                    }
                }

                var allEvents: [Event] = []
                for try await batchEvents in group {
                    allEvents.append(contentsOf: batchEvents)
                }
                return allEvents
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
            bookmarkedEvents = []
        }
    }

    // MARK: - Toggle Bookmark (Optimistic Update)
    func toggleBookmark(for event: Event) async {
        guard let eventId = event.id,
              let userId = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else {
            return
        }

        // Prevent simultaneous toggles
        guard isTogglingBookmark[eventId] != true else { return }

        let isCurrentlyBookmarked = bookmarkStatus[eventId] ?? false

        // Set loading state
        isTogglingBookmark[eventId] = true

        // OPTIMISTIC UPDATE (instant UI feedback)
        bookmarkStatus[eventId] = !isCurrentlyBookmarked

        if isCurrentlyBookmarked {
            // Remove from list
            bookmarkedEvents.removeAll { $0.id == eventId }
        } else {
            // Add to list at top
            if !bookmarkedEvents.contains(where: { $0.id == eventId }) {
                bookmarkedEvents.insert(event, at: 0)
            }
        }

        // SYNC TO SERVER (background)
        do {
            if isCurrentlyBookmarked {
                try await bookmarkRepository.removeBookmark(userId: userId, eventId: eventId)
            } else {
                let bookmark = BookmarkData(
                    id: UUID().uuidString,
                    eventId: eventId,
                    eventName: event.name,
                    venue: event.venue,
                    startTime: event.startTime ?? Date(),
                    eventPrice: event.price,
                    eventImageUrl: event.imageUrl,
                    bookmarkedAt: Date()
                )
                try await bookmarkRepository.addBookmark(userId: userId, bookmark: bookmark)
            }

            // Success haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

        } catch {
            // REVERT OPTIMISTIC UPDATE (rollback)
            bookmarkStatus[eventId] = isCurrentlyBookmarked

            if isCurrentlyBookmarked {
                // Tried to remove but failed - add back
                if !bookmarkedEvents.contains(where: { $0.id == eventId }) {
                    bookmarkedEvents.insert(event, at: 0)
                }
            } else {
                // Tried to add but failed - remove
                bookmarkedEvents.removeAll { $0.id == eventId }
            }

            // Show error to user
            bookmarkError = BookmarkError(
                eventId: eventId,
                eventName: event.name,
                message: "Failed to update bookmark: \(error.localizedDescription)"
            )
        }

        isTogglingBookmark[eventId] = false
    }

    // MARK: - Helper Methods
    func isBookmarked(_ eventId: String) -> Bool {
        return bookmarkStatus[eventId] ?? false
    }

    // Called on pull-to-refresh
    func refreshBookmarks() async {
        await loadBookmarks()
    }

    func clearBookmarks() {
        bookmarkedEvents = []
        bookmarkStatus = [:]
    }

    func clearError() {
        bookmarkError = nil
    }
}
