import Foundation
import Shared
import Supabase

/**
 * Swift adapters for KMP repositories
 * These wrap the Kotlin Multiplatform shared repositories for easy use in SwiftUI
 */

// MARK: - Supabase Client Initialization
class KMPSupabaseManager {
    static let shared = KMPSupabaseManager()

    private var supabaseClient: Shared.SupabaseClient?
    private var authClient: Shared.AuthClient?

    private init() {}

    /// Initialize KMP Supabase client with app configuration
    func initialize(url: String, anonKey: String) {
        self.supabaseClient = Shared.SupabaseClient(url: url, anonKey: anonKey)

        // Initialize AuthClient with the same Supabase client
        if let client = supabaseClient?.getKtorClient() {
            self.authClient = Shared.AuthClient(supabaseClient: client)
        }
    }

    func getSupabaseClient() -> Shared.SupabaseClient? {
        return supabaseClient
    }

    func getAuthClient() -> Shared.AuthClient? {
        return authClient
    }
}

// MARK: - Event Repository Adapter
@MainActor
class KMPEventRepositoryAdapter: ObservableObject {
    private let repository: Shared.EventRepository

    init() {
        guard let client = KMPSupabaseManager.shared.getSupabaseClient() else {
            fatalError("KMP Supabase client not initialized. Call KMPSupabaseManager.shared.initialize() first.")
        }
        self.repository = Shared.EventRepository(supabaseClient: client)
    }

    /// Fetch events since a specific date
    func fetchEvents(since date: Date, page: Int32? = nil, pageSize: Int32? = nil) async throws -> [Shared.Event] {
        let instant = date.toKotlinInstant()

        let result = try await repository.fetchEvents(
            sinceDate: instant,
            page: page.map { KotlinInt(int: $0) },
            pageSize: pageSize.map { KotlinInt(int: $0) }
        )

        switch result {
        case let successResult as ResultSuccess<NSArray>:
            return (successResult.value as? [Shared.Event]) ?? []
        case let failureResult as ResultFailure<NSArray>:
            throw failureResult.exception
        default:
            return []
        }
    }

    /// Fetch a single event by ID
    func fetchEvent(eventId: String) async throws -> Shared.Event? {
        let result = try await repository.fetchEvent(eventId: eventId)

        switch result {
        case let successResult as ResultSuccess<Shared.Event>:
            return successResult.value
        case let failureResult as ResultFailure<Shared.Event>:
            throw failureResult.exception
        default:
            return nil
        }
    }

    /// Fetch featured events
    func getFeaturedEvents(limit: Int32 = 5) async throws -> [Shared.Event] {
        let result = try await repository.getFeaturedEvents(limit: limit)

        switch result {
        case let successResult as ResultSuccess<NSArray>:
            return (successResult.value as? [Shared.Event]) ?? []
        case let failureResult as ResultFailure<NSArray>:
            throw failureResult.exception
        default:
            return []
        }
    }

    /// Get this week's events
    func getThisWeekEvents(limit: Int32 = 20) async throws -> [Shared.Event] {
        let result = try await repository.getThisWeekEvents(limit: limit)

        switch result {
        case let successResult as ResultSuccess<NSArray>:
            return (successResult.value as? [Shared.Event]) ?? []
        case let failureResult as ResultFailure<NSArray>:
            throw failureResult.exception
        default:
            return []
        }
    }

    /// Get nearby events
    func getNearbyEvents(latitude: Double, longitude: Double, radiusKm: Double = 50.0, limit: Int32 = 20) async throws -> [Shared.Event] {
        let result = try await repository.getNearbyEvents(
            lat: latitude,
            lon: longitude,
            radiusKm: radiusKm,
            limit: limit
        )

        switch result {
        case let successResult as ResultSuccess<NSArray>:
            return (successResult.value as? [Shared.Event]) ?? []
        case let failureResult as ResultFailure<NSArray>:
            throw failureResult.exception
        default:
            return []
        }
    }

    /// Search events
    func searchEvents(
        query: String,
        sortBy: Shared.SearchSortOption = .date,
        userLat: Double? = nil,
        userLon: Double? = nil
    ) async throws -> [Shared.Event] {
        let result = try await repository.searchEvents(
            query: query,
            sortBy: sortBy,
            userLat: userLat.map { KotlinDouble(double: $0) },
            userLon: userLon.map { KotlinDouble(double: $0) }
        )

        switch result {
        case let successResult as ResultSuccess<NSArray>:
            return (successResult.value as? [Shared.Event]) ?? []
        case let failureResult as ResultFailure<NSArray>:
            throw failureResult.exception
        default:
            return []
        }
    }
}

// MARK: - Ticket Repository Adapter
@MainActor
class KMPTicketRepositoryAdapter: ObservableObject {
    private let repository: Shared.TicketRepository

    init() {
        guard let client = KMPSupabaseManager.shared.getSupabaseClient() else {
            fatalError("KMP Supabase client not initialized")
        }
        self.repository = Shared.TicketRepository(supabaseClient: client)
    }

    /// Fetch user tickets
    func fetchUserTickets(userId: String) async throws -> [Shared.Ticket] {
        let result = try await repository.fetchUserTickets(userId: userId)

        switch result {
        case let successResult as ResultSuccess<NSArray>:
            return (successResult.value as? [Shared.Ticket]) ?? []
        case let failureResult as ResultFailure<NSArray>:
            throw failureResult.exception
        default:
            return []
        }
    }

    /// Check if user has a ticket for an event
    func userHasTicket(userId: String, eventId: String) async throws -> Bool {
        let result = try await repository.userHasTicket(userId: userId, eventId: eventId)

        switch result {
        case let successResult as ResultSuccess<KotlinBoolean>:
            return successResult.value.boolValue
        case let failureResult as ResultFailure<KotlinBoolean>:
            throw failureResult.exception
        default:
            return false
        }
    }

    /// Fetch ticket status for multiple events
    func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool] {
        let result = try await repository.fetchUserTicketStatus(userId: userId, eventIds: eventIds)

        switch result {
        case let successResult as ResultSuccess<NSDictionary>:
            var statusDict: [String: Bool] = [:]
            if let dict = successResult.value as? [String: Any] {
                for (key, value) in dict {
                    if let boolValue = (value as? KotlinBoolean)?.boolValue {
                        statusDict[key] = boolValue
                    }
                }
            }
            return statusDict
        case let failureResult as ResultFailure<NSDictionary>:
            throw failureResult.exception
        default:
            return [:]
        }
    }
}

// MARK: - Bookmark Repository Adapter
@MainActor
class KMPBookmarkRepositoryAdapter: ObservableObject {
    private let repository: Shared.BookmarkRepository

    init() {
        guard let client = KMPSupabaseManager.shared.getSupabaseClient() else {
            fatalError("KMP Supabase client not initialized")
        }
        self.repository = Shared.BookmarkRepository(supabaseClient: client)
    }

    /// Fetch user bookmarks
    func fetchBookmarks(userId: String) async throws -> [Shared.Bookmark] {
        let result = try await repository.fetchBookmarks(userId: userId)

        switch result {
        case let successResult as ResultSuccess<NSArray>:
            return (successResult.value as? [Shared.Bookmark]) ?? []
        case let failureResult as ResultFailure<NSArray>:
            throw failureResult.exception
        default:
            return []
        }
    }

    /// Add bookmark
    func addBookmark(userId: String, event: Shared.Event) async throws {
        let result = try await repository.addBookmark(userId: userId, event: event)

        if let failureResult = result as? ResultFailure<KotlinUnit> {
            throw failureResult.exception
        }
    }

    /// Remove bookmark
    func removeBookmark(userId: String, eventId: String) async throws {
        let result = try await repository.removeBookmark(userId: userId, eventId: eventId)

        if let failureResult = result as? ResultFailure<KotlinUnit> {
            throw failureResult.exception
        }
    }

    /// Check if event is bookmarked
    func isBookmarked(userId: String, eventId: String) async throws -> Bool {
        let result = try await repository.isBookmarked(userId: userId, eventId: eventId)

        switch result {
        case let successResult as ResultSuccess<KotlinBoolean>:
            return successResult.value.boolValue
        case let failureResult as ResultFailure<KotlinBoolean>:
            throw failureResult.exception
        default:
            return false
        }
    }
}

// MARK: - User Repository Adapter
@MainActor
class KMPUserRepositoryAdapter: ObservableObject {
    private let repository: Shared.UserRepository

    init() {
        guard let client = KMPSupabaseManager.shared.getSupabaseClient() else {
            fatalError("KMP Supabase client not initialized")
        }
        self.repository = Shared.UserRepository(supabaseClient: client)
    }

    /// Fetch user profile
    func fetchUserProfile(userId: String) async throws -> Shared.User? {
        let result = try await repository.fetchUserProfile(userId: userId)

        switch result {
        case let successResult as ResultSuccess<Shared.User>:
            return successResult.value
        case let failureResult as ResultFailure<Shared.User>:
            throw failureResult.exception
        default:
            return nil
        }
    }

    /// Update user profile
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        let result = try await repository.updateUserProfile(userId: userId, data: data)

        if let failureResult = result as? ResultFailure<KotlinUnit> {
            throw failureResult.exception
        }
    }

    /// Check if user exists
    func userExists(userId: String) async throws -> Bool {
        let result = try await repository.userExists(userId: userId)

        switch result {
        case let successResult as ResultSuccess<KotlinBoolean>:
            return successResult.value.boolValue
        case let failureResult as ResultFailure<KotlinBoolean>:
            throw failureResult.exception
        default:
            return false
        }
    }
}

// MARK: - Auth Service Adapter
@MainActor
class KMPAuthServiceAdapter: ObservableObject {
    private let service: Shared.AuthService

    init() {
        guard let authClient = KMPSupabaseManager.shared.getAuthClient(),
              let supabaseClient = KMPSupabaseManager.shared.getSupabaseClient() else {
            fatalError("KMP clients not initialized")
        }

        let userRepo = Shared.UserRepository(supabaseClient: supabaseClient)
        self.service = Shared.AuthService(authClient: authClient, userRepository: userRepo)
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> String {
        let result = try await service.signInWithEmail(email: email, password: password)

        if let success = result as? AuthResultSuccess {
            return success.userId
        } else if let error = result as? AuthResultError {
            throw NSError(domain: "AuthError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: error.message
            ])
        }

        throw NSError(domain: "AuthError", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Unknown error"
        ])
    }

    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String) async throws -> String {
        let result = try await service.signUpWithEmail(
            email: email,
            password: password,
            displayName: displayName
        )

        if let success = result as? AuthResultSuccess {
            return success.userId
        } else if let error = result as? AuthResultError {
            throw NSError(domain: "AuthError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: error.message
            ])
        }

        throw NSError(domain: "AuthError", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Unknown error"
        ])
    }

    /// Sign out
    func signOut() async throws {
        let result = try await service.signOut()

        if let failureResult = result as? ResultFailure<KotlinUnit> {
            throw failureResult.exception
        }
    }

    /// Reset password
    func resetPassword(email: String) async throws {
        let result = try await service.resetPassword(email: email)

        if let failureResult = result as? ResultFailure<KotlinUnit> {
            throw failureResult.exception
        }
    }

    /// Get current user ID
    func getCurrentUserId() -> String? {
        return service.getCurrentUserId()
    }

    /// Check if authenticated
    func isAuthenticated() -> Bool {
        return service.isAuthenticated()
    }
}
