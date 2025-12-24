import Foundation
import Shared


/**
 * Converters between Swift models (Codable for Supabase) and KMP shared models
 *
 * Swift models remain for Supabase operations (which require Codable).
 * These converters allow seamless use of KMP business logic with Swift data.
 */

// MARK: - Coordinate Converters

extension Coordinate {
    /// Convert Swift Coordinate to KMP Coordinate
    func toKMP() -> Shared.Coordinate {
        return Shared.Coordinate(latitude: self.latitude, longitude: self.longitude)
    }
}

extension Shared.Coordinate {
    /// Convert KMP Coordinate to Swift Coordinate
    func toSwift() -> Coordinate {
        return Coordinate(latitude: self.latitude, longitude: self.longitude)
    }
}

// MARK: - Event Converters

extension Event {
    /// Convert Swift Event to KMP Event
    func toKMP() -> Shared.Event {
        return Shared.Event(
            id: self.id,
            name: self.name,
            venue: self.venue,
            venueId: self.venueId,
            startTime: self.startTime?.toKMPInstantString(),
            endTime: self.endTime?.toKMPInstantString(),
            price: self.price,
            maxTickets: Int32(self.maxTickets),
            ticketsSold: Int32(self.ticketsSold),
            imageUrl: self.imageUrl,
            isFeatured: self.isFeatured,
            featuredPriority: self.featuredPriority.map { KotlinInt(int: Int32($0)) },
            description: self.description,
            status: self.status,
            tags: self.tags,
            coordinates: self.coordinates?.toKMP(),
            createdAt: self.createdAt?.toKMPInstantString(),
            updatedAt: self.updatedAt?.toKMPInstantString()
        )
    }
}

extension Shared.Event {
    /// Convert KMP Event to Swift Event
    func toSwift() -> Event {
        return Event(
            id: self.id,
            name: self.name,
            venue: self.venue,
            venueId: self.venueId,
            startTime: self.startTime.flatMap { $0.toSwiftDate() },
            endTime: self.endTime.flatMap { $0.toSwiftDate() },
            price: self.price,
            maxTickets: Int(self.maxTickets),
            ticketsSold: Int(self.ticketsSold),
            imageUrl: self.imageUrl,
            isFeatured: self.isFeatured,
            featuredPriority: self.featuredPriority.map { Int($0.int32Value) },
            description: self.description,
            status: self.status,
            tags: self.tags,
            coordinates: self.coordinates?.toSwift(),
            createdAt: self.createdAt.flatMap { $0.toSwiftDate() },
            updatedAt: self.updatedAt.flatMap { $0.toSwiftDate() }
        )
    }
}

// MARK: - Ticket Converters

extension Ticket {
    /// Convert Swift Ticket to KMP Ticket
    func toKMP() -> Shared.Ticket {
        return Shared.Ticket(
            ticketId: self.ticketId,
            eventId: self.eventId,
            userId: self.userId,
            ticketNumber: self.ticketNumber,
            eventName: self.eventName,
            venue: self.venue,
            startTime: self.startTime.toKMPInstantString(),
            totalPrice: self.totalPrice.map { KotlinDouble(double: $0) },
            purchaseDate: self.purchaseDate.toKMPInstantString(),
            status: self.status,
            qrCode: self.qrCode,
            venueId: self.venueId,
            paymentIntentId: self.paymentIntentId,
            usedAt: self.usedAt?.toKMPInstantString(),
            scannedBy: self.scannedBy,
            cancelledAt: self.cancelledAt?.toKMPInstantString(),
            cancelReason: self.cancelReason,
            refundedAt: self.refundedAt?.toKMPInstantString(),
            refundAmount: self.refundAmount.map { KotlinDouble(double: $0) },
            transferredFrom: self.transferredFrom,
            transferredAt: self.transferredAt?.toKMPInstantString(),
            deletedAt: self.deletedAt?.toKMPInstantString(),
            updatedAt: self.updatedAt?.toKMPInstantString()
        )
    }
}

extension Shared.Ticket {
    /// Convert KMP Ticket to Swift Ticket
    func toSwift() -> Ticket {
        return Ticket(
            ticketId: self.ticketId,
            eventId: self.eventId,
            userId: self.userId,
            ticketNumber: self.ticketNumber,
            eventName: self.eventName,
            venue: self.venue,
            startTime: self.startTime?.toSwiftDate() ?? Date(),
            totalPrice: self.totalPrice?.doubleValue,
            purchaseDate: self.purchaseDate?.toSwiftDate() ?? Date(),
            status: self.status,
            qrCode: self.qrCode,
            venueId: self.venueId,
            paymentIntentId: self.paymentIntentId,
            usedAt: self.usedAt.flatMap { $0.toSwiftDate() },
            scannedBy: self.scannedBy,
            cancelledAt: self.cancelledAt.flatMap { $0.toSwiftDate() },
            cancelReason: self.cancelReason,
            refundedAt: self.refundedAt.flatMap { $0.toSwiftDate() },
            refundAmount: self.refundAmount?.doubleValue,
            transferredFrom: self.transferredFrom,
            transferredAt: self.transferredAt.flatMap { $0.toSwiftDate() },
            deletedAt: self.deletedAt.flatMap { $0.toSwiftDate() },
            updatedAt: self.updatedAt.flatMap { $0.toSwiftDate() }
        )
    }
}

// MARK: - Tag Converters

extension Tag {
    /// Convert Swift Tag to KMP Tag
    func toKMP() -> Shared.Tag {
        return Shared.Tag(
            id: self.id,
            name: self.name,
            order: Int32(self.order),
            active: self.active,
            color: self.color,
            description: self.description
        )
    }
}

extension Shared.Tag {
    /// Convert KMP Tag to Swift Tag
    func toSwift() -> Tag {
        // Tag doesn't have a memberwise init, so we decode from a dictionary
        let dict: [String: Any] = [
            "id": self.id as Any,
            "name": self.name,
            "description": self.description as Any,
            "color": self.color as Any,
            "order": Int(self.order),
            "active": self.active
        ]

        let data = try! JSONSerialization.data(withJSONObject: dict)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Tag.self, from: data)
    }
}

// MARK: - Venue Converters

extension Venue {
    /// Convert Swift Venue to KMP Venue
    func toKMP() -> Shared.Venue {
        return Shared.Venue(
            id: self.id,
            name: self.name,
            address: self.address,
            city: self.city,
            capacity: Int32(self.capacity),
            imageUrl: self.imageUrl,
            contactEmail: self.contactEmail,
            website: self.website,
            admins: self.admins,
            subAdmins: self.subAdmins,
            active: self.active,
            eventCount: Int32(self.eventCount),
            createdAt: self.createdAt?.toKMPInstantString(),
            createdBy: self.createdBy,
            updatedAt: self.updatedAt?.toKMPInstantString(),
            coordinates: self.coordinates?.toKMP()
        )
    }
}

extension Shared.Venue {
    /// Convert KMP Venue to Swift Venue
    func toSwift() -> Venue {
        return Venue(
            id: self.id,
            name: self.name,
            address: self.address,
            city: self.city,
            capacity: Int(self.capacity),
            imageUrl: self.imageUrl,
            contactEmail: self.contactEmail,
            website: self.website,
            admins: Array(self.admins),
            subAdmins: Array(self.subAdmins),
            active: self.active,
            eventCount: Int(self.eventCount),
            createdAt: self.createdAt.flatMap { $0.toSwiftDate() },
            createdBy: self.createdBy,
            updatedAt: self.updatedAt.flatMap { $0.toSwiftDate() },
            coordinates: self.coordinates?.toSwift()
        )
    }
}

// MARK: - Date Conversion Utilities

extension Date {
    /// Convert Swift Date to KMP Instant string (ISO 8601 format)
    func toKMPInstantString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

extension String {
    /// Convert ISO 8601 string to Swift Date
    func toSwiftDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return date
        }
        
        // Fallback to standard format without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }
}

// MARK: - Array Converters

extension Array where Element == Event {
    /// Convert array of Swift Events to KMP Events
    func toKMP() -> [Shared.Event] {
        return self.map { $0.toKMP() }
    }
}

extension Array where Element == Shared.Event {
    /// Convert array of KMP Events to Swift Events
    func toSwift() -> [Event] {
        return self.map { $0.toSwift() }
    }
}

extension Array where Element == Ticket {
    /// Convert array of Swift Tickets to KMP Tickets
    func toKMP() -> [Shared.Ticket] {
        return self.map { $0.toKMP() }
    }
}

extension Array where Element == Shared.Ticket {
    /// Convert array of KMP Tickets to Swift Tickets
    func toSwift() -> [Ticket] {
        return self.map { $0.toSwift() }
    }
}

extension Array where Element == Tag {
    /// Convert array of Swift Tags to KMP Tags
    func toKMP() -> [Shared.Tag] {
        return self.map { $0.toKMP() }
    }
}

extension Array where Element == Shared.Tag {
    /// Convert array of KMP Tags to Swift Tags
    func toSwift() -> [Tag] {
        return self.map { $0.toSwift() }
    }
}

extension Array where Element == Venue {
    /// Convert array of Swift Venues to KMP Venues
    func toKMP() -> [Shared.Venue] {
        return self.map { $0.toKMP() }
    }
}

extension Array where Element == Shared.Venue {
    /// Convert array of KMP Venues to Swift Venues
    func toSwift() -> [Venue] {
        return self.map { $0.toSwift() }
    }
}
