import Foundation
import Combine

// MARK: - Shared Types
// ADDED: Hashable
struct Coordinate: Codable, Sendable, Hashable {
    let latitude: Double
    let longitude: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode latitude, handle string-encoded numbers
        if let lat = try? container.decode(Double.self, forKey: .latitude) {
            latitude = lat
        } else if let latString = try? container.decode(String.self, forKey: .latitude),
                  let lat = Double(latString) {
            latitude = lat
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .latitude,
                in: container,
                debugDescription: "Invalid latitude value"
            )
        }

        // Try to decode longitude, handle string-encoded numbers
        if let lng = try? container.decode(Double.self, forKey: .longitude) {
            longitude = lng
        } else if let lngString = try? container.decode(String.self, forKey: .longitude),
                  let lng = Double(lngString) {
            longitude = lng
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .longitude,
                in: container,
                debugDescription: "Invalid longitude value"
            )
        }
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Event Model
// ADDED: Hashable
struct Event: Identifiable, Codable, Sendable, Hashable {
    var id: String?
    var name: String
    var venue: String
    var venueId: String?

    // Date fields
    var startTime: Date?
    var endTime: Date?

    var price: Double
    var maxTickets: Int
    var ticketsSold: Int
    var imageUrl: String
    var isFeatured: Bool
    var featuredPriority: Int?
    var description: String?

    var status: String?
    var tags: [String]?

    var coordinates: Coordinate?

    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, venue
        case venueId = "venue_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case price  // Database column is just "price", not "ticket_price"
        case maxTickets = "max_tickets"
        case ticketsSold = "tickets_sold"
        case imageUrl = "image_url"
        case isFeatured = "is_featured"
        case featuredPriority = "featured_priority"
        case description, status, tags, coordinates
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Memberwise initializer
    init(
        id: String? = nil,
        name: String,
        venue: String,
        venueId: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        price: Double,
        maxTickets: Int,
        ticketsSold: Int,
        imageUrl: String,
        isFeatured: Bool,
        featuredPriority: Int? = nil,
        description: String? = nil,
        status: String? = nil,
        tags: [String]? = nil,
        coordinates: Coordinate? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.venue = venue
        self.venueId = venueId
        self.startTime = startTime
        self.endTime = endTime
        self.price = price
        self.maxTickets = maxTickets
        self.ticketsSold = ticketsSold
        self.imageUrl = imageUrl
        self.isFeatured = isFeatured
        self.featuredPriority = featuredPriority
        self.description = description
        self.status = status
        self.tags = tags
        self.coordinates = coordinates
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder to handle bad coordinate data gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        venue = try container.decode(String.self, forKey: .venue)
        venueId = try container.decodeIfPresent(String.self, forKey: .venueId)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        price = try container.decode(Double.self, forKey: .price)
        maxTickets = try container.decode(Int.self, forKey: .maxTickets)
        ticketsSold = try container.decode(Int.self, forKey: .ticketsSold)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        featuredPriority = try container.decodeIfPresent(Int.self, forKey: .featuredPriority)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)

        // Try to decode coordinates, but don't fail the whole event if they're bad
        coordinates = try? container.decodeIfPresent(Coordinate.self, forKey: .coordinates)

        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

}

// MARK: - Ticket Model
struct Ticket: Identifiable, Codable, Sendable {
    // Primary identifier - renamed from 'id' to 'ticketId'
    var ticketId: String?
    
    // Identity
    var eventId: String
    var userId: String
    var ticketNumber: String?
    
    // Event info (fallback data)
    var eventName: String
    var venue: String
    var startTime: Date
    
    // Purchase info
    var totalPrice: Double?
    var purchaseDate: Date
    
    // Status & QR
    var status: String
    var qrCode: String?

    // Optional metadata
    var venueId: String?
    var paymentIntentId: String?

    var usedAt: Date?
    var scannedBy: String?
    var cancelledAt: Date?
    var cancelReason: String?
    var refundedAt: Date?
    var refundAmount: Double?
    var transferredFrom: String?
    var transferredAt: Date?
    var deletedAt: Date?

    var updatedAt: Date?
    
    // Computed property for Identifiable conformance
    var id: String? { ticketId }
    
    enum CodingKeys: String, CodingKey {
        case ticketId = "ticket_id"
        case eventId = "event_id"
        case userId = "user_id"
        case ticketNumber = "ticket_number"
        case eventName = "event_name"
        case startTime = "start_time"
        case totalPrice = "total_price"
        case purchaseDate = "purchase_date"
        case status
        case qrCode = "qr_code"
        case venueId = "venue_id"
        case paymentIntentId = "payment_intent_id"
        case usedAt = "used_at"
        case scannedBy = "scanned_by"
        case cancelledAt = "cancelled_at"
        case cancelReason = "cancel_reason"
        case refundedAt = "refunded_at"
        case refundAmount = "refund_amount"
        case transferredFrom = "transferred_from"
        case transferredAt = "transferred_at"
        case deletedAt = "deleted_at"
        case updatedAt = "updated_at"
        case venue
    }
}

// MARK: - Supporting Types

struct TicketWithEventData: Codable, Identifiable, Sendable {
    let ticket: Ticket
    let event: Event
    var id: String {
        ticket.ticketId ?? UUID().uuidString
    }
}

// MARK: - Event Extensions

extension Event {
    var isPast: Bool {
        guard let startTime = startTime else { return true }
        let calendar = Calendar.current
        let nextDayEnd = calendar.dateInterval(of: .day, for: startTime)?.end ?? startTime
        let nextDay6AM = calendar.date(byAdding: .hour, value: 6, to: nextDayEnd) ?? startTime
        return Date() > nextDay6AM
    }

    /// Determines if the event has started
    var hasStarted: Bool {
        guard let startTime = startTime else { return false }
        return Date() >= startTime
    }
}
