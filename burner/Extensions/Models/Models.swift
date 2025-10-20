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
    var description: String?
    
    // Additional fields from Phase 4
    var status: String? // "active", "soldOut", "past"
    var category: String? // "general", etc.
    var tags: [String]?
    var organizerId: String?
    
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
    var status: String // "confirmed", "cancelled", "used"
    var qrCode: String?
    
    // Optional metadata
    var venueId: String?
    
    // Optional status tracking (added when ticket is scanned/cancelled)
    var usedAt: Date?
    var scannedBy: String?
    var cancelledAt: Date?
    var cancelReason: String?
    var refundedAt: Date?
    var refundAmount: Double?
    var transferredFrom: String?
    var transferredAt: Date?
    
    var updatedAt: Date?
    
    // Computed property for backward compatibility
    var ticketPrice: Double {
        return totalPrice
    }
}
