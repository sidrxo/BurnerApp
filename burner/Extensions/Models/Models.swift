import Foundation
import Combine
import Shared

// MARK: - Type Aliases
// Map Swift types to KMP types for seamless migration

typealias Event = Shared.Event
typealias Ticket = Shared.Ticket
typealias Coordinate = Shared.Coordinate
typealias TicketWithEventData = Shared.TicketWithEventData

// MARK: - Swift Extensions for KMP Types
// Add Swift-specific functionality to make KMP types work seamlessly in iOS

extension Shared.Event: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(venue)
    }

    public static func == (lhs: Shared.Event, rhs: Shared.Event) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.venue == rhs.venue
    }
}

extension Shared.Event {
    /// Convert KMP startInstant to Swift Date
    var startTime: Date? {
        guard let instant = startInstant else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    /// Convert KMP endInstant to Swift Date
    var endTime: Date? {
        guard let instant = endInstant else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

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

extension Shared.Ticket {
    /// Convert KMP startInstant to Swift Date
    var startTime: Date {
        return Date(timeIntervalSince1970: Double(startInstant.epochSeconds))
    }

    /// Convert KMP purchaseInstant to Swift Date
    var purchaseDate: Date {
        return Date(timeIntervalSince1970: Double(purchaseInstant.epochSeconds))
    }

    /// Convert optional KMP instants to Swift Dates
    var usedAt: Date? {
        guard let instant = usedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var cancelledAt: Date? {
        guard let instant = cancelledAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var refundedAt: Date? {
        guard let instant = refundedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var transferredAt: Date? {
        guard let instant = transferredAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var deletedAt: Date? {
        guard let instant = deletedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }

    var updatedAt: Date? {
        guard let instant = updatedAt else { return nil }
        return Date(timeIntervalSince1970: Double(instant.epochSeconds))
    }
}

extension Shared.Coordinate: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: Shared.Coordinate, rhs: Shared.Coordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Ticket Status Constants
// Make TicketStatus constants easily accessible
extension String {
    static let ticketStatusConfirmed = "confirmed"
    static let ticketStatusCancelled = "cancelled"
    static let ticketStatusRefunded = "refunded"
    static let ticketStatusUsed = "used"
}
