import Foundation
import FirebaseAuth
import FirebaseFunctions
import Combine

// MARK: - Refactored Event ViewModel
@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var userTicketStatus: [String: Bool] = [:]
    
    private let eventRepository: EventRepository
    private let ticketRepository: TicketRepository
    private let purchaseService: PurchaseService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        eventRepository: EventRepository = EventRepository(),
        ticketRepository: TicketRepository = TicketRepository(),
        purchaseService: PurchaseService = PurchaseService()
    ) {
        self.eventRepository = eventRepository
        self.ticketRepository = ticketRepository
        self.purchaseService = purchaseService
    }
    
    // MARK: - Fetch Events
    func fetchEvents() {
        isLoading = true
        
        eventRepository.observeEvents { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isLoading = false
                
                switch result {
                case .success(let events):
                    self.events = events
                    await self.refreshUserTicketStatus()
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Refresh User Ticket Status
    private func refreshUserTicketStatus() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            userTicketStatus.removeAll()
            return
        }
        
        let eventIds = events.compactMap { $0.id }
        
        do {
            userTicketStatus = try await ticketRepository.fetchUserTicketStatus(
                userId: userId,
                eventIds: eventIds
            )
        } catch {
            print("Error fetching ticket status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Check Single Ticket Status
    func checkUserTicketStatus(for eventId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        Task {
            do {
                let hasTicket = try await ticketRepository.userHasTicket(
                    userId: userId,
                    eventId: eventId
                )
                
                await MainActor.run {
                    self.userTicketStatus[eventId] = hasTicket
                    completion(hasTicket)
                }
            } catch {
                print("Error checking ticket status: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - User Has Ticket
    func userHasTicket(for eventId: String) -> Bool {
        return userTicketStatus[eventId] ?? false
    }
    
    // MARK: - Purchase Ticket
    func purchaseTicket(eventId: String, completion: @escaping (Bool, String?) -> Void) {
        if userHasTicket(for: eventId) {
            completion(false, "You already have a ticket for this event")
            return
        }
        
        guard Auth.auth().currentUser != nil else {
            completion(false, "Please log in to purchase a ticket")
            return
        }
        
        Task {
            do {
                let result = try await purchaseService.purchaseTicket(eventId: eventId)
                
                await MainActor.run {
                    if result.success {
                        self.successMessage = result.message
                        self.userTicketStatus[eventId] = true
                        self.fetchEvents() // Refresh to update sold count
                        completion(true, result.message)
                    } else {
                        self.errorMessage = result.message
                        completion(false, result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    let errorMsg = self.handleError(error)
                    self.errorMessage = errorMsg
                    completion(false, errorMsg)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) -> String {
        if let nsError = error as NSError? {
            switch nsError.code {
            case FunctionsErrorCode.unauthenticated.rawValue:
                return "Authentication failed. Please log out and log back in."
            case FunctionsErrorCode.permissionDenied.rawValue:
                return "Permission denied. Please check your account."
            case FunctionsErrorCode.notFound.rawValue:
                return "Event not found."
            case FunctionsErrorCode.invalidArgument.rawValue:
                return "Invalid purchase details."
            case FunctionsErrorCode.failedPrecondition.rawValue:
                return error.localizedDescription.contains("already have") ?
                    "You already have a ticket for this event" :
                    "Event sold out or unavailable."
            case FunctionsErrorCode.internal.rawValue:
                return "Server error. Please try again."
            case FunctionsErrorCode.unavailable.rawValue:
                return "Service temporarily unavailable. Please try again."
            case FunctionsErrorCode.deadlineExceeded.rawValue:
                return "Request timed out. Please try again."
            default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }
    
    // MARK: - Clear Messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Cleanup
    func cleanup() {
        eventRepository.stopObserving()
        cancellables.removeAll()
    }
}

// MARK: - Refactored Bookmark Manager
@MainActor
class BookmarkManager: ObservableObject {
    @Published var bookmarkedEvents: [Event] = []
    @Published var bookmarkStatus: [String: Bool] = [:]
    @Published var isLoading = false
    
    private let bookmarkRepository: BookmarkRepository
    private let eventRepository: EventRepository
    
    init(
        bookmarkRepository: BookmarkRepository = BookmarkRepository(),
        eventRepository: EventRepository = EventRepository()
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.eventRepository = eventRepository
        setupBookmarkListener()
    }
    
    // MARK: - Setup Listener
    private func setupBookmarkListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        bookmarkRepository.observeBookmarks(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
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
                    print("❌ Error fetching bookmarks: \(error.localizedDescription)")
                }
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
        
        // Fetch all events (you could optimize this to only fetch bookmarked ones)
        var events: [Event] = []
        for eventId in eventIds {
            if let event = try? await eventRepository.fetchEvent(by: eventId) {
                events.append(event)
            }
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
    }
    
    // MARK: - Toggle Bookmark
    func toggleBookmark(for event: Event) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let eventId = event.id else {
            print("❌ User not authenticated or invalid event ID")
            return
        }
        
        let isCurrentlyBookmarked = bookmarkStatus[eventId] ?? false
        
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
                    eventDate: event.date,
                    eventPrice: event.price,
                    eventImageUrl: event.imageUrl,
                    bookmarkedAt: Date()
                )
                try await bookmarkRepository.addBookmark(userId: userId, bookmark: bookmark)
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            // Revert optimistic update on error
            bookmarkStatus[eventId] = isCurrentlyBookmarked
            print("❌ Error toggling bookmark: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    func isBookmarked(_ eventId: String) -> Bool {
        return bookmarkStatus[eventId] ?? false
    }
    
    func clearBookmarks() {
        bookmarkedEvents = []
        bookmarkStatus = [:]
        bookmarkRepository.stopObserving()
    }
}

// MARK: - Tickets ViewModel (NEW)
@MainActor
class TicketsViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let ticketRepository: TicketRepository
    
    init(ticketRepository: TicketRepository = TicketRepository()) {
        self.ticketRepository = ticketRepository
    }
    
    // MARK: - Fetch User Tickets
    func fetchUserTickets() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user")
            return
        }
        
        isLoading = true
        
        ticketRepository.observeUserTickets(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isLoading = false
                
                switch result {
                case .success(let tickets):
                    self.tickets = tickets
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load tickets: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        ticketRepository.stopObserving()
    }
}
