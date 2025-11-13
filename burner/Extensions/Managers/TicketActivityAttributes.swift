import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct TicketActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var eventStartTime: Date
        var eventEndTime: Date?
        var hasEventStarted: Bool
        var hasEventEnded: Bool
        var progress: Double // 0.0 to 1.0
    }

    var eventName: String
    var venue: String
    var startTime: Date
    var endTime: Date?
}
