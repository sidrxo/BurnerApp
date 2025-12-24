import Foundation
import Combine
import Shared // ✅ Import KMP

@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarkedEventIds: Set<String> = []
    // ✅ Restored the missing property
    @Published var isTogglingBookmark: [String: Bool] = [:]
    
    private let bookmarkRepository: Shared.BookmarkRepository
    private let eventViewModel: EventViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(bookmarkRepository: Shared.BookmarkRepository, eventViewModel: EventViewModel) {
        self.bookmarkRepository = bookmarkRepository
        self.eventViewModel = eventViewModel
    }
    
    func isBookmarked(_ eventId: String) -> Bool {
        return bookmarkedEventIds.contains(eventId)
    }
    
    func toggleBookmark(for event: Shared.Event) {
        guard let eventId = event.id else { return }
        
        // Update UI immediately (Optimistic UI)
        isTogglingBookmark[eventId] = true
        
        if bookmarkedEventIds.contains(eventId) {
            bookmarkedEventIds.remove(eventId)
            Task {
                // Perform async removal
                // try? await bookmarkRepository.removeBookmark(...)
                self.isTogglingBookmark[eventId] = false
            }
        } else {
            bookmarkedEventIds.insert(eventId)
            Task {
                // Perform async add
                // try? await bookmarkRepository.addBookmark(...)
                self.isTogglingBookmark[eventId] = false
            }
        }
    }
}
