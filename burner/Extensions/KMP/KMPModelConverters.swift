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
            startInstant: self.startTime?.toKMPInstant(),
            endInstant: self.endTime?.toKMPInstant(),
            price: self.price,
            maxTickets: Int32(self.maxTickets),
            ticketsSold: Int32(self.ticketsSold),
            imageUrl: self.imageUrl,
            isFeatured: self.isFeatured,
            featuredPriority: self.featuredPriority.map { Int32($0) },
            description: self.description,
            status: self.status,
            tags: self.tags,
            coordinates: self.coordinates?.toKMP(),
            createdAt: self.createdAt?.toKMPInstant(),
            updatedAt: self.updatedAt?.toKMPInstant()
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
            startTime: self.startInstant?.toSwiftDate(),
            endTime: self.endInstant?.toSwiftDate(),
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
            createdAt: self.createdAt?.toSwiftDate(),
            updatedAt: self.updatedAt?.toSwiftDate()
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
            startTime: self.startTime.toKMPInstant(),
            totalPrice: self.totalPrice,
            purchaseDate: self.purchaseDate.toKMPInstant(),
            status: self.status,
            qrCode: self.qrCode,
            venueId: self.venueId,
            paymentIntentId: self.paymentIntentId,
            usedAt: self.usedAt?.toKMPInstant(),
            scannedBy: self.scannedBy,
            cancelledAt: self.cancelledAt?.toKMPInstant(),
            cancelReason: self.cancelReason,
            refundedAt: self.refundedAt?.toKMPInstant(),
            refundAmount: self.refundAmount,
            transferredFrom: self.transferredFrom,
            transferredAt: self.transferredAt?.toKMPInstant(),
            deletedAt: self.deletedAt?.toKMPInstant(),
            updatedAt: self.updatedAt?.toKMPInstant()
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
            startTime: self.startTime.toSwiftDate(),
            totalPrice: self.totalPrice,
            purchaseDate: self.purchaseDate.toSwiftDate(),
            status: self.status,
            qrCode: self.qrCode,
            venueId: self.venueId,
            paymentIntentId: self.paymentIntentId,
            usedAt: self.usedAt?.toSwiftDate(),
            scannedBy: self.scannedBy,
            cancelledAt: self.cancelledAt?.toSwiftDate(),
            cancelReason: self.cancelReason,
            refundedAt: self.refundedAt?.toSwiftDate(),
            refundAmount: self.refundAmount,
            transferredFrom: self.transferredFrom,
            transferredAt: self.transferredAt?.toSwiftDate(),
            deletedAt: self.deletedAt?.toSwiftDate(),
            updatedAt: self.updatedAt?.toSwiftDate()
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
            nameLowercase: self.nameLowercase,
            description: self.description,
            color: self.color,
            order: Int32(self.order),
            active: self.active,
            createdAt: self.createdAt?.toKMPInstant(),
            updatedAt: self.updatedAt?.toKMPInstant()
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
            "nameLowercase": self.nameLowercase as Any,
            "description": self.description as Any,
            "color": self.color as Any,
            "order": Int(self.order),
            "active": self.active,
            "createdAt": self.createdAt?.toSwiftDate() as Any,
            "updatedAt": self.updatedAt?.toSwiftDate() as Any
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
            coordinates: self.coordinates?.toKMP(),
            createdAt: self.createdAt?.toKMPInstant(),
            createdBy: self.createdBy,
            updatedAt: self.updatedAt?.toKMPInstant()
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
            createdAt: self.createdAt?.toSwiftDate(),
            createdBy: self.createdBy,
            updatedAt: self.updatedAt?.toSwiftDate(),
            coordinates: self.coordinates?.toSwift()
        )
    }
}

// MARK: - Date Conversion Utilities

extension Date {
    /// Convert Swift Date to KMP Instant
    func toKMPInstant() -> Kotlinx_datetimeInstant {
        let seconds = Int64(self.timeIntervalSince1970)
        let nanoseconds = Int32((self.timeIntervalSince1970 - Double(seconds)) * 1_000_000_000)
        return Kotlinx_datetimeInstant.Companion().fromEpochSeconds(
            epochSeconds: seconds,
            nanosecondAdjustment: nanoseconds
        )
    }
}

extension Kotlinx_datetimeInstant {
    /// Convert KMP Instant to Swift Date
    func toSwiftDate() -> Date {
        return Date(timeIntervalSince1970: Double(self.epochSeconds))
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
