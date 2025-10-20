import Foundation
import ActivityKit

@available(iOS 16.1, *)
class TicketLiveActivityManager {
    
    static func startLiveActivity(for ticketWithEvent: TicketWithEventData) {
        // Create attributes
        let attributes = TicketActivityAttributes(
            eventName: ticketWithEvent.event.name,
            venue: ticketWithEvent.event.venue,
            startTime: ticketWithEvent.event.startTime ?? Date()
        )
        
        // Create content state
        let contentState = TicketActivityAttributes.ContentState(
            timeUntilEvent: calculateTimeUntilEvent(ticketWithEvent.event.startTime ?? Date(),)
        )
        
        do {
            if #available(iOS 16.2, *) {
                _ = try Activity<TicketActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: nil
                )
            } else {
                _ = try Activity<TicketActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            }
        } catch {
            print("Error starting live activity: \(error)")
        }
    }
    
    static func updateLiveActivity() {
        let activities = Activity<TicketActivityAttributes>.activities
        
        for activity in activities {
            let newContentState = TicketActivityAttributes.ContentState(
                timeUntilEvent: calculateTimeUntilEvent(activity.attributes.startTime)
            )
            
            Task {
                if #available(iOS 16.2, *) {
                    await activity.update(.init(state: newContentState, staleDate: nil))
                } else {
                    await activity.update(using: newContentState)
                }
            }
        }
    }
    
    static func endLiveActivity() {
        let activities = Activity<TicketActivityAttributes>.activities
        
        for activity in activities {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }
    
    private static func calculateTimeUntilEvent(_ startTime: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDate(startTime, inSameDayAs: now) {
            let components = calendar.dateComponents([.hour, .minute], from: now, to: startTime)
            
            if startTime <= now {
                return "Event Started"
            } else if let hours = components.hour, let minutes = components.minute {
                if hours > 0 {
                    return "\(hours)h \(minutes)m"
                } else {
                    return "\(minutes)m"
                }
            }
        }
        
        let components = calendar.dateComponents([.day], from: now, to: startTime)
        if let days = components.day {
            if days == 0 {
                return "Today"
            } else if days == 1 {
                return "Tomorrow"
            } else {
                return "\(days) days"
            }
        }
        
        return "Soon"
    }
}
