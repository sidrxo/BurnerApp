import Foundation
import Shared

/**
 * Swift helpers for using KMP shared types
 *
 * This provides simple wrappers around the shared KMP business logic.
 * iOS continues to use its existing Swift-based repositories for now.
 */

// MARK: - Business Logic Helpers

/// Helper for filtering events using shared KMP logic
@MainActor
class KMPEventFilteringHelper {
    private let useCase = Shared.EventFilteringUseCase()

    /// Filter featured events
    func filterFeatured(events: [Shared.Event], limit: Int32 = 5) -> [Shared.Event] {
        return Array(useCase.filterFeatured(events: events, limit: limit))
    }

    /// Filter events happening this week
    func filterThisWeek(events: [Shared.Event], limit: Int32 = 20) -> [Shared.Event] {
        return Array(useCase.filterThisWeek(events: events, limit: limit))
    }

    /// Filter nearby events
    func filterNearby(
        events: [Shared.Event],
        userLatitude: Double,
        userLongitude: Double,
        radiusKm: Double = 50.0,
        limit: Int32 = 20
    ) -> [Shared.Event] {
        return Array(useCase.filterNearby(
            events: events,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            radiusKm: radiusKm,
            limit: limit
        ))
    }

    /// Filter events by genre
    func filterByGenre(events: [Shared.Event], genre: String) -> [Shared.Event] {
        return Array(useCase.filterByGenre(events: events, genre: genre))
    }

    /// Filter available events
    func filterAvailable(events: [Shared.Event]) -> [Shared.Event] {
        return Array(useCase.filterAvailable(events: events))
    }

    /// Filter upcoming events
    func filterUpcoming(events: [Shared.Event]) -> [Shared.Event] {
        return Array(useCase.filterUpcoming(events: events))
    }
}

/// Helper for searching events using shared KMP logic
@MainActor
class KMPSearchHelper {
    private let useCase = Shared.SearchUseCase()

    /// Search events by query
    func searchEvents(events: [Shared.Event], query: String) -> [Shared.Event] {
        return Array(useCase.searchEvents(events: events, query: query))
    }

    /// Sort events
    func sortEvents(
        events: [Shared.Event],
        sortBy: Shared.SearchSortOption,
        userLatitude: Double? = nil,
        userLongitude: Double? = nil
    ) -> [Shared.Event] {
        let userLat = userLatitude.map { KotlinDouble(double: $0) }
        let userLon = userLongitude.map { KotlinDouble(double: $0) }

        return Array(useCase.sortEvents(
            events: events,
            sortBy: sortBy,
            userLatitude: userLat,
            userLongitude: userLon
        ))
    }

    /// Search and sort events
    func searchAndSort(
        events: [Shared.Event],
        query: String,
        sortBy: Shared.SearchSortOption,
        userLatitude: Double? = nil,
        userLongitude: Double? = nil,
        limit: Int32? = nil
    ) -> [Shared.Event] {
        let userLat = userLatitude.map { KotlinDouble(double: $0) }
        let userLon = userLongitude.map { KotlinDouble(double: $0) }
        let kotlinLimit = limit.map { KotlinInt(int: $0) }

        return Array(useCase.searchAndSort(
            events: events,
            query: query,
            sortBy: sortBy,
            userLatitude: userLat,
            userLongitude: userLon,
            limit: kotlinLimit as! Int32
        ))
    }
}

/// Helper for ticket status tracking using shared KMP logic
@MainActor
class KMPTicketStatusHelper {
    private let tracker = Shared.TicketStatusTracker()

    /// Get active tickets
    func getActiveTickets(tickets: [Shared.Ticket]) -> [Shared.Ticket] {
        return Array(tracker.getActiveTickets(tickets: tickets))
    }

    /// Get past tickets
    func getPastTickets(tickets: [Shared.Ticket]) -> [Shared.Ticket] {
        return Array(tracker.getPastTickets(tickets: tickets))
    }

    /// Get tickets for a specific event
    func getTicketsForEvent(tickets: [Shared.Ticket], eventId: String) -> [Shared.Ticket] {
        return Array(tracker.getTicketsForEvent(tickets: tickets, eventId: eventId))
    }

    /// Check if user has confirmed ticket for event
    func hasConfirmedTicket(tickets: [Shared.Ticket], eventId: String) -> Bool {
        return tracker.hasConfirmedTicket(tickets: tickets, eventId: eventId)
    }

    /// Get total spent on tickets
    func getTotalSpent(tickets: [Shared.Ticket]) -> Double {
        return tracker.getTotalSpent(tickets: tickets)
    }

    /// Sort tickets by purchase date
    func sortByPurchaseDate(tickets: [Shared.Ticket], ascending: Bool = false) -> [Shared.Ticket] {
        return Array(tracker.sortByPurchaseDate(tickets: tickets, ascending: ascending))
    }

    /// Sort tickets by event date
    func sortByEventDate(tickets: [Shared.Ticket], ascending: Bool = true) -> [Shared.Ticket] {
        return Array(tracker.sortByEventDate(tickets: tickets, ascending: ascending))
    }
}

// MARK: - Utility Helpers

/// Wrapper for shared DateUtils
/// Note: DateUtils is an object in Kotlin, accessed directly without .companion
struct KMPDateUtils {
    /// Format date
    static func formatDate(_ instant: Kotlinx_datetimeInstant, timeZone: Kotlinx_datetimeTimeZone) -> String {
        return Shared.DateUtils().formatDate(instant: instant, timeZone: timeZone)
    }

    /// Format time
    static func formatTime(_ instant: Kotlinx_datetimeInstant, timeZone: Kotlinx_datetimeTimeZone) -> String {
        return Shared.DateUtils().formatTime(instant: instant, timeZone: timeZone)
    }

    /// Format date and time
    static func formatDateTime(_ instant: Kotlinx_datetimeInstant, timeZone: Kotlinx_datetimeTimeZone) -> String {
        return Shared.DateUtils().formatDateTime(instant: instant, timeZone: timeZone)
    }

    /// Get relative time string (e.g., "2 hours ago")
    static func getRelativeTimeString(_ instant: Kotlinx_datetimeInstant) -> String {
        return Shared.DateUtils().getRelativeTimeString(instant: instant)
    }
}

/// Wrapper for shared PriceUtils
struct KMPPriceUtils {
    /// Format price with currency symbol
    static func formatPrice(_ price: Double, currencySymbol: String = "$") -> String {
        return Shared.PriceUtils().formatPrice(price: price, currencySymbol: currencySymbol)
    }

    /// Format price range
    static func formatPriceRange(
        minPrice: Double,
        maxPrice: Double,
        currencySymbol: String = "$"
    ) -> String {
        return Shared.PriceUtils().formatPriceRange(
            minPrice: minPrice,
            maxPrice: maxPrice,
            currencySymbol: currencySymbol
        )
    }

    /// Convert cents to dollars
    static func centsToDollars(_ cents: Int32) -> Double {
        return Shared.PriceUtils().centsToDollars(cents: Int64(cents))
    }

    /// Convert dollars to cents
    static func dollarsToCents(_ dollars: Double) -> Int32 {
        return Int32(Shared.PriceUtils().dollarsToCents(dollars: dollars))
    }
}

/// Utility to calculate distance between coordinates
/// Note: GeoUtils functions are package-level in Kotlin, not in a class
struct KMPGeoUtils {
    /// Calculate distance between two coordinates in kilometers

}
