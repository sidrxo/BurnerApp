import Swift
import Combine
import FirebaseAuth
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
        setupBookmarkListener()
    }
    
    // MARK: - Setup Listener
    private func setupBookmarkListener() {
        guard !isSimulatingEmptyData else { return }

        bookmarkRepository.stopObserving()

        guard let userId = Auth.auth().currentUser?.uid else { return }

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

                case .failure:
                    break
                }
            }
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

        // Split event IDs into batches of 10 (Firestore whereIn limit)
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
            // Fallback to empty array on error
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
    
    // MARK: - Toggle Bookmark
    func toggleBookmark(for event: Event) async {
        guard !isSimulatingEmptyData else { return }

        guard let userId = Auth.auth().currentUser?.uid,
              let eventId = event.id else {
            return
        }

        // Prevent multiple simultaneous toggles for the same event
        guard isTogglingBookmark[eventId] != true else { return }

        let isCurrentlyBookmarked = bookmarkStatus[eventId] ?? false

        // Set loading state
        await MainActor.run {
            isTogglingBookmark[eventId] = true
        }

        // Optimistic update
        bookmarkStatus[eventId] = !isCurrentlyBookmarked

        do {
            if isCurrentlyBookmarked {
                try await bookmarkRepository.removeBookmark(userId: userId, eventId: eventId)
            } else {
                let bookmark = BookmarkData(
                    eventId: eventId,
                    eventName: event.name,
                    eventVenue: event.venue,
                    startTime: event.startTime ?? Date(),
                    eventPrice: event.price,
                    eventImageUrl: event.imageUrl,
                    bookmarkedAt: Date()
                )
                try await bookmarkRepository.addBookmark(userId: userId, bookmark: bookmark)
            }

            // Haptic feedback on success
            await MainActor.run {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                isTogglingBookmark[eventId] = false
            }

        } catch {
            // Revert optimistic update on error
            await MainActor.run {
                self.bookmarkStatus[eventId] = isCurrentlyBookmarked
                self.isTogglingBookmark[eventId] = false

                // Show error with retry option
                self.bookmarkError = BookmarkError(
                    eventId: eventId,
                    eventName: event.name,
                    message: AppConstants.ErrorMessages.bookmarkFailed
                )

                
                print("❌ Bookmark Error: \(error.localizedDescription)")
                
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
        setupBookmarkListener()
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
        setupBookmarkListener()
    }
    
}
