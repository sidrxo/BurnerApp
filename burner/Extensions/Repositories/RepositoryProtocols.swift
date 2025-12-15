import Foundation
import CoreLocation

protocol EventRepositoryProtocol {
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void)
    func fetchEventsFromServer(since date: Date, page: Int?, pageSize: Int?) async throws -> [Event]
    func eventStream(since date: Date) -> AsyncThrowingStream<[Event], Error>
    func fetchEvent(by id: String) async throws -> Event?
    func stopObserving()
}

protocol TicketRepositoryProtocol {
    func observeUserTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void)
    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool]
    func userHasTicket(userId: String, eventId: String) async throws -> Bool
    func stopObserving()
}

protocol BookmarkRepositoryProtocol {
    func observeBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void)
    func addBookmark(userId: String, bookmark: BookmarkData) async throws
    func removeBookmark(userId: String, eventId: String) async throws
    func stopObserving()
}

protocol UserRepositoryProtocol {
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func updateUserProfile(userId: String, data: [String: Any]) async throws
    func createUserProfile(userId: String, profile: UserProfile) async throws
    func userExists(userId: String) async throws -> Bool
    // User repository usually doesn't need stopObserving unless you listen to profile changes
}

// Add this to your RepositoryProtocols.swift file
// Replace the makeEventViewModel() function with this:

@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()

    private(set) var eventRepository: EventRepositoryProtocol
    private(set) var ticketRepository: TicketRepositoryProtocol
    private(set) var bookmarkRepository: BookmarkRepositoryProtocol
    private(set) var userRepository: UserRepositoryProtocol
    private(set) var userLocationManager: UserLocationManager
    private(set) var burnerManager: BurnerModeManager

    private init() {
        self.eventRepository = EventRepository()
        self.ticketRepository = TicketRepository()
        self.bookmarkRepository = BookmarkRepository()
        self.userRepository = UserRepository()
        self.userLocationManager = UserLocationManager()
        self.burnerManager = BurnerModeManager()
    }

    func setEventRepository(_ repository: EventRepositoryProtocol) {
        self.eventRepository = repository
    }

    func setTicketRepository(_ repository: TicketRepositoryProtocol) {
        self.ticketRepository = repository
    }

    func setBookmarkRepository(_ repository: BookmarkRepositoryProtocol) {
        self.bookmarkRepository = repository
    }

    func setUserRepository(_ repository: UserRepositoryProtocol) {
        self.userRepository = repository
    }

    func resetToDefaults() {
        self.eventRepository = EventRepository()
        self.ticketRepository = TicketRepository()
        self.bookmarkRepository = BookmarkRepository()
        self.userRepository = UserRepository()
    }

    func makeEventViewModel() -> EventViewModel {
        // FIXED: Create EventViewModel without TicketsViewModel initially
        let eventVM = EventViewModel(
            eventRepository: eventRepository,
            ticketRepository: ticketRepository
        )
        
        // Create TicketsViewModel
        let ticketsVM = makeTicketsViewModel()
        
        // Connect them
        eventVM.setTicketsViewModel(ticketsVM)
        
        return eventVM
    }

    func makeBookmarkManager() -> BookmarkManager {
        return BookmarkManager(
            bookmarkRepository: bookmarkRepository as! BookmarkRepository,
            eventRepository: eventRepository as! EventRepository
        )
    }

    func makeTicketsViewModel() -> TicketsViewModel {
        return TicketsViewModel(
            ticketRepository: ticketRepository
        )
    }
}

