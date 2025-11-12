// AppConstants.swift

import Foundation
import CoreLocation

/// Centralized constants for the Burner app
struct AppConstants {

    // MARK: - Distance & Location

    /// Maximum distance for "nearby" events (in meters) - approximately 31 miles
    static let maxNearbyDistanceMeters: CLLocationDistance = 50_000

    // MARK: - Search & Pagination

    /// Initial number of events to load in search results
    static let searchInitialLoadLimit = 6

    /// Cache time-to-live for search results (in seconds)
    static let searchCacheTTL: TimeInterval = 300 // 5 minutes

    /// Debounce interval for search text input (in milliseconds)
    static let searchDebounceMilliseconds = 300

    // MARK: - Burner Mode

    /// Minimum number of categories required for Burner Mode
    static let burnerModeMinCategories = 8

    // MARK: - Firestore

    /// Maximum items per Firestore 'whereIn' query
    static let firestoreWhereInLimit = 10

    // MARK: - Animation

    /// Standard animation duration for UI transitions
    static let standardAnimationDuration = 0.2

    // MARK: - Empty State Messages

    struct EmptyState {
        static let noBookmarks = "Tap ♡ on any event to save it here"
        static let noTickets = "The best night of your life is one click away."
        static let noTicketsButton = "BROWSE EVENTS"
        static let noSearchResults = "Try different keywords"
        static let noUpcomingEvents = "There are no upcoming events available at the moment."
        static let meetMeInTheMoment = "MEET ME IN THE MOMENT"
    }

    // MARK: - Error Messages

    struct ErrorMessages {
        static let locationNotAvailable = "Location not available. Please enable location services."
        static let bookmarkFailed = "Failed to update bookmark. Please try again."
        static let paymentFailed = "Payment failed. Please try again."
        static let notAuthenticated = "Please sign in to continue."
        static let networkError = "Network error. Please check your connection and try again."
    }
}
