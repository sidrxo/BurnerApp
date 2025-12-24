import Foundation
import Combine
import Shared

// MARK: - Type Alias
// Map Swift Venue to KMP Venue

typealias Venue = Shared.Venue

// MARK: - Swift Extensions for KMP Venue
// Add Swift-specific functionality

extension Shared.Venue {
    /// Convert KMP createdAt to Swift Date
    var createdAt: Date? {
        guard let instant = createdAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    /// Convert KMP updatedAt to Swift Date
    var updatedAt: Date? {
        guard let instant = updatedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }
}
