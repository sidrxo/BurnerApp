import Foundation
import CoreLocation

protocol EventRepositoryProtocol {
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void)
    func fetchEventsFromServer(since date: Date) async throws -> [Event]
    func eventStream(since date: Date) -> AsyncThrowingStream<[Event], Error>
}

protocol TicketRepositoryProtocol {
    func observeUserTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void)
    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool]
    func userHasTicket(userId: String, eventId: String) async throws -> Bool
}

protocol BookmarkRepositoryProtocol {
    func observeBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void)
    func addBookmark(userId: String, bookmark: BookmarkData) async throws
    func removeBookmark(userId: String, eventId: String) async throws
}

protocol UserRepositoryProtocol {
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func updateUserProfile(userId: String, data: [String: Any]) async throws
    func createUserProfile(userId: String, profile: UserProfile) async throws
    func userExists(userId: String) async throws -> Bool
}

extension EventRepository: EventRepositoryProtocol {}
extension TicketRepository: TicketRepositoryProtocol {}
extension BookmarkRepository: BookmarkRepositoryProtocol {}
extension UserRepository: UserRepositoryProtocol {}

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
        return EventViewModel(
            eventRepository: eventRepository,
            ticketRepository: ticketRepository
        )
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

class MockEventRepository: EventRepositoryProtocol {
    var mockEvents: [Event] = []
    var shouldFail = false
    var observeCalled = false

    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        observeCalled = true
        if shouldFail {
            completion(.failure(NSError(domain: "MockError", code: -1, userInfo: nil)))
        } else {
            completion(.success(mockEvents))
        }
    }

    func fetchEventsFromServer(since date: Date) async throws -> [Event] {
        if shouldFail {
            throw NSError(domain: "MockError", code: -1, userInfo: nil)
        }
        return mockEvents
    }

    func eventStream(since date: Date) -> AsyncThrowingStream<[Event], Error> {
        return AsyncThrowingStream { continuation in
            if shouldFail {
                continuation.finish(throwing: NSError(domain: "MockError", code: -1, userInfo: nil))
            } else {
                continuation.yield(mockEvents)
                continuation.finish()
            }
        }
    }
}

class MockTicketRepository: TicketRepositoryProtocol {
    var mockTickets: [Ticket] = []
    var mockTicketStatus: [String: Bool] = [:]

    func observeUserTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void) {
        completion(.success(mockTickets))
    }

    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool] {
        return mockTicketStatus
    }

    func userHasTicket(userId: String, eventId: String) async throws -> Bool {
        return mockTicketStatus[eventId] ?? false
    }
}

class MockBookmarkRepository: BookmarkRepositoryProtocol {
    var mockBookmarks: [BookmarkData] = []
    var addCalled = false
    var removeCalled = false

    func observeBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void) {
        completion(.success(mockBookmarks))
    }

    func addBookmark(userId: String, bookmark: BookmarkData) async throws {
        addCalled = true
        mockBookmarks.append(bookmark)
    }

    func removeBookmark(userId: String, eventId: String) async throws {
        removeCalled = true
        mockBookmarks.removeAll { $0.eventId == eventId }
    }
}
