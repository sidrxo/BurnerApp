// RepositoryProtocols.swift
// Protocol definitions for dependency injection and testing

import Foundation
import CoreLocation

// MARK: - Event Repository Protocol
protocol EventRepositoryProtocol {
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void)
    func stopObserving()
}

// MARK: - Ticket Repository Protocol
protocol TicketRepositoryProtocol {
    func observeUserTickets(userId: String, completion: @escaping (Result<[Ticket], Error>) -> Void)
    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool]
    func userHasTicket(userId: String, eventId: String) async throws -> Bool
    func stopObserving()
}

// MARK: - Bookmark Repository Protocol
protocol BookmarkRepositoryProtocol {
    func observeBookmarks(userId: String, completion: @escaping (Result<[BookmarkData], Error>) -> Void)
    func addBookmark(userId: String, bookmark: BookmarkData) async throws
    func removeBookmark(userId: String, eventId: String) async throws
    func stopObserving()
}

// MARK: - User Repository Protocol
protocol UserRepositoryProtocol {
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func updateUserProfile(userId: String, data: [String: Any]) async throws
    func createUserProfile(userId: String, profile: UserProfile) async throws
    func userExists(userId: String) async throws -> Bool
}

// MARK: - Make existing repositories conform to protocols
// These extensions make existing implementations work with DI
extension EventRepository: EventRepositoryProtocol {}
extension TicketRepository: TicketRepositoryProtocol {}
extension BookmarkRepository: BookmarkRepositoryProtocol {}
extension UserRepository: UserRepositoryProtocol {}

// MARK: - Dependency Container
/// Simple dependency injection container for managing app-wide dependencies
@MainActor
class DependencyContainer {
    // MARK: - Singleton
    static let shared = DependencyContainer()

    // MARK: - Repositories (Protocols for testability)
    private(set) var eventRepository: EventRepositoryProtocol
    private(set) var ticketRepository: TicketRepositoryProtocol
    private(set) var bookmarkRepository: BookmarkRepositoryProtocol
    private(set) var userRepository: UserRepositoryProtocol

    // MARK: - Services
    private(set) var userLocationManager: UserLocationManager

    // MARK: - Managers
    private(set) var burnerManager: BurnerModeManager

    private init() {
        // Initialize with production implementations
        self.eventRepository = EventRepository()
        self.ticketRepository = TicketRepository()
        self.bookmarkRepository = BookmarkRepository()
        self.userRepository = UserRepository()
        self.userLocationManager = UserLocationManager()
        self.burnerManager = BurnerModeManager()
    }

    // MARK: - Dependency Injection (for testing)
    #if DEBUG
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
    #endif

    // MARK: - Factory Methods
    func makeEventViewModel() -> EventViewModel {
        return EventViewModel(
            eventRepository: eventRepository as! EventRepository,
            ticketRepository: ticketRepository as! TicketRepository
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
            ticketRepository: ticketRepository as! TicketRepository
        )
    }
}

// MARK: - Mock Repositories (for testing)
#if DEBUG

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

    func stopObserving() {}
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

    func stopObserving() {}
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

    func stopObserving() {}
}

#endif
