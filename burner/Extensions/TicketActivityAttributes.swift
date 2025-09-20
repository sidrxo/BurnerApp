import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct TicketActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeUntilEvent: String
    }
    
    var eventName: String
    var venue: String
    var eventDate: Date
}
