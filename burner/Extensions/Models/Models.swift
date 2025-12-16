import Foundation

// MARK: - Shared Types
struct Coordinate: Codable, Sendable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Event Model
struct Event: Identifiable, Codable, Sendable {
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

    // Custom decoder to handle NULL values with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        venue = try container.decodeIfPresent(String.self, forKey: .venue) ?? "Unknown Venue"
        venueId = try container.decodeIfPresent(String.self, forKey: .venueId)

        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)

        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        maxTickets = try container.decodeIfPresent(Int.self, forKey: .maxTickets) ?? 0
        ticketsSold = try container.decodeIfPresent(Int.self, forKey: .ticketsSold) ?? 0
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        featuredPriority = try container.decodeIfPresent(Int.self, forKey: .featuredPriority)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        status = try container.decodeIfPresent(String.self, forKey: .status)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        coordinates = try container.decodeIfPresent(Coordinate.self, forKey: .coordinates)

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
