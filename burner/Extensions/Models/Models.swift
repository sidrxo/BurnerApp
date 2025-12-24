import Foundation
import Shared // ✅ Import KMP

// Wrapper for tickets to include event data
// Updated to use Shared types
struct TicketWithEventData: Identifiable, Hashable {
    let ticket: Shared.Ticket
    let event: Shared.Event
    
    var id: String {
        return ticket.id ?? UUID().uuidString
    }
    
    // Hashable conformance for KMP classes
    func hash(into hasher: inout Hasher) {
        hasher.combine(ticket.id)
        hasher.combine(event.id)
    }
    
    static func == (lhs: TicketWithEventData, rhs: TicketWithEventData) -> Bool {
        return lhs.ticket.id == rhs.ticket.id && lhs.event.id == rhs.event.id
    }
}
