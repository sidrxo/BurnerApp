import Swift
import Combine
import Supabase
import UIKit


@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarkedEvents: [Event] = []
    @Published var bookmarkStatus: [String: Bool] = [:]
    @Published var isLoading = false
    @Published var isTogglingBookmark: [String: Bool] = [:]
    @Published var bookmarkError: BookmarkError?

    private let bookmarkRepository: BookmarkRepository
    private let eventRepository: EventRepository
    private var isSimulatingEmptyData = false

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
        
        // Call async setup in Task
        Task {
            await setupBookmarkListener()
        }
    }
    
    // MARK: - Setup Listener
    // MARK: - Setup Listener
        private func setupBookmarkListener() async {
            guard !isSimulatingEmptyData else { return }

            // This call cancels any existing task, which triggers the 'cancelled' error
            // in the previous observer if one was active.
            bookmarkRepository.stopObserving()

            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString
                
                bookmarkRepository.observeBookmarks(userId: userId) { [weak self] result in
                    guard let self = self else { return }

                    Task { @MainActor in
                        guard !self.isSimulatingEmptyData else { return }

                        switch result {
                        case .success(let bookmarks):
                            // Update bookmark status dictionary
                            var newStatus: [String: Bool] = [:]
                            for bookmark in bookmarks {
                                newStatus[bookmark.eventId] = true
                            }
                            self.bookmarkStatus = newStatus

                            // Fetch full event details
                            await self.fetchBookmarkedEvents(bookmarks: bookmarks)

                        case .failure(let error):
                            // MARK: - FIX STARTS HERE
                            // Silently ignore cancellation errors
                            let nsError = error as NSError
                            if error is CancellationError ||
                               nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled ||
                               nsError.localizedDescription.lowercased() == "cancelled" {
                                return
                            }
                            // MARK: - FIX ENDS HERE
                        }
                    }
                }
            } catch {
                // Failed to get user session
            }
        }
    
    // MARK: - Fetch Bookmarked Events (Optimized with Batch Fetching)
    private func fetchBookmarkedEvents(bookmarks: [BookmarkData]) async {
        let eventIds = bookmarks.map { $0.eventId }

        guard !eventIds.isEmpty else {
            bookmarkedEvents = []
            return
        }

        // Fetch events in batches using whereIn (max 10 per query)
        var events: [Event] = []

        // Split event IDs into batches of 10
        let batchSize = 10
        let batches = stride(from: 0, to: eventIds.count, by: batchSize).map {
            Array(eventIds[$0..<min($0 + batchSize, eventIds.count)])
        }

        // Fetch all batches in parallel
        do {
            events = try await withThrowingTaskGroup(of: [Event].self) { group in
                for batch in batches {
                    group.addTask {
                        return try await self.eventRepository.fetchEvents(by: batch)
                    }
                }

                var allEvents: [Event] = []
                for try await batchEvents in group {
                    allEvents.append(contentsOf: batchEvents)
                }
                return allEvents
            }
        } catch {
            events = []
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

        await MainActor.run {
            self.bookmarkedEvents = sortedEvents
        }
    }

    func toggleBookmark(for event: Event) async {
        guard !isSimulatingEmptyData else {
            return
        }

        let userId: String
        let eventId: String
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            userId = session.user.id.uuidString
            
            guard let unwrappedEventId = event.id else { return }
            eventId = unwrappedEventId
            
        } catch {
            // ... (existing error handling)
            return
        }

        // Prevent multiple simultaneous toggles
        guard isTogglingBookmark[eventId] != true else { return }

        let isCurrentlyBookmarked = bookmarkStatus[eventId] ?? false

        // Set loading state
        await MainActor.run {
            isTogglingBookmark[eventId] = true
            
            // --- 1. OPTIMISTIC UPDATE START ---
            
            // A. Update the Status (Icon)
            bookmarkStatus[eventId] = !isCurrentlyBookmarked
            
            // B. Update the List (The View)
            if isCurrentlyBookmarked {
                // We are removing: Filter it out immediately
                bookmarkedEvents.removeAll { $0.id == eventId }
            } else {
                // We are adding: Add it to the list immediately
                // Check if it exists just to be safe
                if !bookmarkedEvents.contains(where: { $0.id == eventId }) {
                    // Insert at the top (index 0) so it appears as the most recent save
                    bookmarkedEvents.insert(event, at: 0)
                }
            }
            // --- OPTIMISTIC UPDATE END ---
        }

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

            await MainActor.run {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                isTogglingBookmark[eventId] = false
            }

        } catch {
            // --- 2. REVERT OPTIMISTIC UPDATE ON ERROR ---
            await MainActor.run {
                self.bookmarkStatus[eventId] = isCurrentlyBookmarked
                self.isTogglingBookmark[eventId] = false
                
                // Revert the list change
                if isCurrentlyBookmarked {
                    // We tried to remove but failed -> Add it back
                    if !bookmarkedEvents.contains(where: { $0.id == eventId }) {
                        bookmarkedEvents.insert(event, at: 0)
                    }
                } else {
                    // We tried to add but failed -> Remove it
                    bookmarkedEvents.removeAll { $0.id == eventId }
                }

                self.bookmarkError = BookmarkError(
                    eventId: eventId,
                    eventName: event.name,
                    message: "Failed to update bookmark: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Clear Error
    func clearError() {
        bookmarkError = nil
    }
    
    // MARK: - Helper Methods
    func isBookmarked(_ eventId: String) -> Bool {
        return bookmarkStatus[eventId] ?? false
    }

    func refreshBookmarks() {
        guard !isSimulatingEmptyData else { return }
        Task {
            await setupBookmarkListener()
        }
    }

    func clearBookmarks() {
        bookmarkedEvents = []
        bookmarkStatus = [:]
        bookmarkRepository.stopObserving()
    }

    // MARK: - Debug helpers
    
    func simulateEmptyData() {
        isSimulatingEmptyData = true
        bookmarkRepository.stopObserving()
        bookmarkedEvents = []
        bookmarkStatus = [:]
        isLoading = false
    }

    func resumeFromSimulation() {
        guard isSimulatingEmptyData else { return }
        isSimulatingEmptyData = false
        Task {
            await setupBookmarkListener()
        }
    }
}
