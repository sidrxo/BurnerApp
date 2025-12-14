import Foundation

struct Venue: Identifiable, Codable, Sendable {
    var id: String?
    var name: String
    var address: String
    var city: String
    var capacity: Int
    var imageUrl: String?
    var contactEmail: String
    var website: String
    var admins: [String]
    var subAdmins: [String]
    var active: Bool
    var eventCount: Int
    var createdAt: Date?
    var createdBy: String?
    var updatedAt: Date?
    
    // Optional fields from Phase 4 enhancement
    var coordinates: Coordinate?
}
