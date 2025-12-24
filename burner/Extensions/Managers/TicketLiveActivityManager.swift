import Foundation
import ActivityKit
import Shared

private let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

class TicketLiveActivityManager {
    
    @available(iOS 16.2, *)
    static func startLiveActivity(for ticket: Shared.Ticket, event: Shared.Event) {
        let startString = event.startTime ?? ""
        let endString = event.endTime ?? ""
        
        let startDate = isoFormatter.date(from: startString) ?? Date()
        let endDate = isoFormatter.date(from: endString) ?? Date().addingTimeInterval(3600)
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // FIX: Matching the arguments from the error message
        let attributes = TicketActivityAttributes(
            eventName: event.name,
            venue: event.venue, // Changed from venueName
            startTime: startDate, // Now passing Date directly
            ticketId: ticket.id ?? "unknown", // Missing arg
            ticketType: ticket.ticketType ?? "General Admission"
        )
        
        let contentState = TicketActivityAttributes.ContentState(
            eventStartTime: startDate,
            eventEndTime: endDate,
            hasEventStarted: Date() >= startDate,
            hasEventEnded: Date() >= endDate
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    static func endLiveActivity() {
        Task {
            for activity in Activity<TicketActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
