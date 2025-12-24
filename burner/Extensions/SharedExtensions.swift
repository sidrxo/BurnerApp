import Foundation
import Shared
import CoreLocation

// MARK: - Event Extensions
extension Shared.Event {
    /// Convert startTime string to Date object for Swift interop
    var startDate: Date? {
        guard let timeString = self.startTime else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timeString) ?? {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: timeString)
        }()
    }

    /// Convert endTime string to Date object for Swift interop
    var endDate: Date? {
        guard let timeString = self.endTime else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timeString) ?? {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: timeString)
        }()
    }

    /// Helper to get coordinates as CLLocation for easy Swift usage
    var location: CLLocation? {
        guard let coords = self.coordinates else { return nil }
        return CLLocation(
            latitude: coords.latitude,
            longitude: coords.longitude
        )
    }

    /// Calculate distance from user location in meters
    func distance(from userLocation: CLLocation) -> CLLocationDistance? {
        guard let eventLocation = location else { return nil }
        return userLocation.distance(from: eventLocation)
    }

    /// Formatted price string
    var formattedPrice: String {
        if price == 0 {
            return "Free"
        }
        return String(format: "$%.2f", price)
    }
}

// MARK: - Ticket Extensions
extension Shared.Ticket {
    /// Convert purchaseDate string to Date object for Swift interop
    var purchaseDateSwift: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self.purchaseDate) ?? {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: self.purchaseDate)
        }() ?? Date()
    }

    /// Check if ticket is active (not deleted/cancelled)
    var isActive: Bool {
        return status != "deleted" && status != "cancelled"
    }

    /// Check if ticket is confirmed
    var isConfirmed: Bool {
        return status == "confirmed"
    }
}

// MARK: - Bookmark Extensions
extension Shared.Bookmark {
    /// Convert bookmarkedAt string to Date object
    var bookmarkedAtDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self.bookmarkedAt) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: self.bookmarkedAt)
        }() ?? Date()
    }
}

// MARK: - User Extensions
extension Shared.User {
    /// Convert createdAt string to Date object
    var createdAtDate: Date? {
        guard let dateString = self.createdAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateString)
        }()
    }

    /// Convert lastLoginAt string to Date object
    var lastLoginAtDate: Date? {
        guard let dateString = self.lastLoginAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateString)
        }()
    }
}

