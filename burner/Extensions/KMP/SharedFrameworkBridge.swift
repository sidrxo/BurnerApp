import Foundation
import SwiftUI
import Shared

// MARK: - Swift Extensions for KMP Types
// This file bridges Kotlin Multiplatform shared types with iOS-specific requirements

// MARK: - Coordinate Extensions
extension Shared.Coordinate {
    /// Convert to iOS CLLocationCoordinate2D if needed
    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Event Extensions
extension Shared.Event: Identifiable {
    // Event is already Identifiable in KMP, but we ensure iOS conformance

    /// Returns the event ID as String, which iOS expects for Identifiable
    public var idString: String {
        return id ?? ""
    }

    /// Computed property for SwiftUI compatibility
    var swiftStartTime: Date? {
        guard let instant = startInstant else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftEndTime: Date? {
        guard let instant = endInstant else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftCreatedAt: Date? {
        guard let instant = createdAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftUpdatedAt: Date? {
        guard let instant = updatedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    /// Check if the event is in the past (already available from KMP)
    var isEventPast: Bool {
        return isPast
    }

    /// Check if the event has started (already available from KMP)
    var eventHasStarted: Bool {
        return hasStarted
    }

    /// Distance from user location (in kilometers)
    func distanceFromUser(latitude: Double, longitude: Double) -> Double? {
        return distanceFrom(userLat: latitude, userLon: longitude)?.doubleValue
    }
}

// MARK: - Ticket Extensions
extension Shared.Ticket: Identifiable {
    // Identifiable conformance - use ticketId as id
    public var idString: String {
        return ticketId ?? ""
    }

    var swiftStartTime: Date {
        return Date(timeIntervalSince1970: Double(startInstant.epochSeconds))
    }

    var swiftPurchaseDate: Date {
        return Date(timeIntervalSince1970: Double(purchaseInstant.epochSeconds))
    }

    var swiftUsedAt: Date? {
        guard let instant = usedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftCancelledAt: Date? {
        guard let instant = cancelledAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftRefundedAt: Date? {
        guard let instant = refundedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftTransferredAt: Date? {
        guard let instant = transferredAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftDeletedAt: Date? {
        guard let instant = deletedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftUpdatedAt: Date? {
        guard let instant = updatedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }
}

// MARK: - TicketStatus Constants
extension Shared.TicketStatus {
    static var confirmed: String { Shared.TicketStatus().cONFIRMED }
    static var cancelled: String { Shared.TicketStatus().cANCELLED }
    static var refunded: String { Shared.TicketStatus().rEFUNDED }
    static var used: String { Shared.TicketStatus().uSED }
}

// MARK: - TicketWithEventData Extensions
extension Shared.TicketWithEventData: Identifiable {
    public var idString: String {
        return ticket.ticketId ?? ""
    }
}

// MARK: - User Extensions
extension Shared.User: Identifiable {
    public var idString: String {
        return id
    }

    var swiftCreatedAt: Date? {
        guard let instant = createdAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftLastLoginAt: Date? {
        guard let instant = lastLoginAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }
}

// MARK: - Venue Extensions
extension Shared.Venue: Identifiable {
    public var idString: String {
        return id ?? ""
    }

    var swiftCreatedAt: Date? {
        guard let instant = createdAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var swiftUpdatedAt: Date? {
        guard let instant = updatedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }
}

// MARK: - Bookmark Extensions
extension Shared.Bookmark: Identifiable {
    public var idString: String {
        return id
    }

    var swiftStartTime: Date {
        return Date(timeIntervalSince1970: Double(startInstant.epochSeconds))
    }

    var swiftBookmarkedAt: Date {
        return Date(timeIntervalSince1970: Double(bookmarkedInstant.epochSeconds))
    }
}

// MARK: - Tag Extensions
extension Shared.Tag: Identifiable {
    public var idString: String {
        return id
    }
}

// MARK: - Async Bridge Helpers
// Helpers to bridge Kotlin suspend functions to Swift async/await

extension Shared.EventRepository {
    /// Fetch events with Swift-friendly async/await
    func fetchEventsAsync(sinceDate: Date, page: Int32? = nil, pageSize: Int32? = nil) async throws -> [Shared.Event] {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchEvents(
                sinceDate: sinceDate.toKotlinInstant(),
                page: page.map { KotlinInt(int: $0) },
                pageSize: pageSize.map { KotlinInt(int: $0) }
            ) { events, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let events = events {
                    continuation.resume(returning: events)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Fetch single event
    func fetchEventAsync(eventId: String) async throws -> Shared.Event? {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchEvent(eventId: eventId) { event, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: event)
                }
            }
        }
    }
}

extension Shared.TicketRepository {
    /// Fetch user tickets with Swift-friendly async/await
    func fetchUserTicketsAsync(userId: String) async throws -> [Shared.Ticket] {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchUserTickets(userId: userId) { tickets, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let tickets = tickets {
                    continuation.resume(returning: tickets)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Check if user has ticket for event
    func userHasTicketAsync(userId: String, eventId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            self.userHasTicket(userId: userId, eventId: eventId) { hasTicket, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: hasTicket?.boolValue ?? false)
                }
            }
        }
    }
}

extension Shared.BookmarkRepository {
    /// Fetch bookmarks with Swift-friendly async/await
    func fetchBookmarksAsync(userId: String) async throws -> [Shared.Bookmark] {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchBookmarks(userId: userId) { bookmarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let bookmarks = bookmarks {
                    continuation.resume(returning: bookmarks)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Add bookmark
    func addBookmarkAsync(userId: String, event: Shared.Event) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.addBookmark(userId: userId, event: event) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Remove bookmark
    func removeBookmarkAsync(userId: String, eventId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.removeBookmark(userId: userId, eventId: eventId) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

extension Shared.UserRepository {
    /// Fetch user profile
    func fetchUserProfileAsync(userId: String) async throws -> Shared.User? {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchUserProfile(userId: userId) { user, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: user)
                }
            }
        }
    }

    /// Update user profile
    func updateUserProfileAsync(userId: String, data: [String: Any]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.updateUserProfile(userId: userId, data: data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Date Conversion Helpers
extension Date {
    /// Convert Swift Date to Kotlin Instant
    func toKotlinInstant() -> Kotlinx_datetimeInstant {
        let epochSeconds = Int64(self.timeIntervalSince1970)
        let nanoseconds = Int32((self.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
        return Kotlinx_datetimeInstant.Companion().fromEpochSeconds(
            epochSeconds: epochSeconds,
            nanosecondAdjustment: nanoseconds
        )
    }
}

extension Kotlinx_datetimeInstant {
    /// Convert Kotlin Instant to Swift Date
    func toSwiftDate() -> Date {
        return Date(timeIntervalSince1970: Double(epochSeconds))
    }
}

// MARK: - Utility Extensions
extension Shared.DateUtils {
    /// Format date using shared utility
    static func formatDate(_ date: Date, timeZone: String = "UTC") -> String {
        return DateUtils.companion.formatDate(
            instant: date.toKotlinInstant(),
            timeZone: timeZone
        )
    }

    /// Format time using shared utility
    static func formatTime(_ date: Date, timeZone: String = "UTC") -> String {
        return DateUtils.companion.formatTime(
            instant: date.toKotlinInstant(),
            timeZone: timeZone
        )
    }

    /// Get relative time string
    static func getRelativeTime(_ date: Date) -> String {
        return DateUtils.companion.getRelativeTimeString(
            instant: date.toKotlinInstant()
        )
    }
}

extension Shared.GeoUtils {
    /// Calculate distance between two coordinates (in km)
    static func calculateDistance(
        from: (lat: Double, lon: Double),
        to: (lat: Double, lon: Double)
    ) -> Double {
        return GeoUtils.companion.haversineDistance(
            lat1: from.lat,
            lon1: from.lon,
            lat2: to.lat,
            lon2: to.lon
        )
    }
}

extension Shared.PriceUtils {
    /// Format price with currency symbol
    static func formatPrice(_ price: Double, currencySymbol: String = "$") -> String {
        return PriceUtils.companion.formatPrice(
            price: price,
            currencySymbol: currencySymbol
        )
    }

    /// Convert cents to dollars
    static func centsToDollars(_ cents: Int32) -> Double {
        return PriceUtils.companion.centsToDollars(cents: cents)
    }

    /// Convert dollars to cents
    static func dollarsToCents(_ dollars: Double) -> Int32 {
        return PriceUtils.companion.dollarsToCents(dollars: dollars)
    }
}
