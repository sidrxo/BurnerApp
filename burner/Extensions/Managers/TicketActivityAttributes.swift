import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct TicketActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeUntilEvent: String
        var hasEventStarted: Bool

        // Helper to format seconds as HH:MM:SS
        static func formatTime(seconds: Int) -> String {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
    }

    var eventName: String
    var venue: String
    var startTime: Date
    var endTime: Date?
}
