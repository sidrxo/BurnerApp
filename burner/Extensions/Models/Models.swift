// Models.swift
import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

// MARK: - Event Model
struct Event: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var name: String
    var venue: String // Keep for display
    var venueId: String? // Reference to venues collection

    // Date fields
    var startTime: Date? // Event start time
    var endTime: Date?   // Event end time

    var price: Double
    var maxTickets: Int
    var ticketsSold: Int
    var imageUrl: String
    var isFeatured: Bool
    var featuredPriority: Int? // Lower number = higher priority (0 = top)
    var description: String?


    var status: String?
    var tags: [String]?

    var coordinates: GeoPoint?

    var createdAt: Date?
    var updatedAt: Date?
}

// MARK: - Ticket Model (Updated for single tickets)
struct Ticket: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    
    // Identity
    var eventId: String
    var userId: String
    var ticketNumber: String?
    
    // Event info (fallback data)
    var eventName: String
    var venue: String
    var startTime: Date
    
    // Purchase info
    var totalPrice: Double
    var purchaseDate: Date
    
    // Status & QR
    var status: String
    var qrCode: String?

    // Optional metadata
    var venueId: String?

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

}

// MARK: - Supporting Types

struct TicketWithEventData: Codable, Identifiable, Sendable {
    let ticket: Ticket
    let event: Event
    var id: String {
        ticket.id ?? UUID().uuidString
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
