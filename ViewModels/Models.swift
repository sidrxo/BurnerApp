import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

// MARK: - Event Model
struct Event: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var name: String
    var venue: String
    var date: Date
    var price: Double
    var maxTickets: Int
    var ticketsSold: Int
    var imageUrl: String
    var isFeatured: Bool
    var description: String?
}

// MARK: - Ticket Model (Updated for single tickets)
struct Ticket: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var eventId: String
    var eventName: String
    var eventDate: Date
    var venue: String
    var userId: String
    var pricePerTicket: Double
    var totalPrice: Double
    var purchaseDate: Date
    var status: String // "confirmed", "cancelled", "used"
    var qrCode: String?
    var ticketNumber: String?
}
