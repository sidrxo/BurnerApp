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
    var eventId: String
    var eventName: String
    var startTime: Date
    var venue: String
    var userId: String
    
    // Price fields
    var purchasePrice: Double?
    var totalPrice: Double
    
    var purchaseDate: Date
    var status: String // "confirmed", "cancelled", "used"
    var qrCode: String?
    var ticketNumber: String?
    
    // Additional fields from Phase 4
    var venueId: String?
    var qrCodeSignature: String?
    var usedAt: Date?
    var scannedBy: String?
    var cancelledAt: Date?
    var cancelReason: String?
    var refundedAt: Date?
    var refundAmount: Double?
    var transferredFrom: String?
    var transferredAt: Date?
    
    var createdAt: Date?
    var updatedAt: Date?
    
    // Computed property to get price (handles both field names)
    var ticketPrice: Double {
        return purchasePrice ?? totalPrice
    }
}
