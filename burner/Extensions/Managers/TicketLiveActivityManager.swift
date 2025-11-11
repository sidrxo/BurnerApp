import Foundation
import ActivityKit

@available(iOS 16.1, *)
class TicketLiveActivityManager {
    
    static func startLiveActivity(for ticketWithEvent: TicketWithEventData) {
        // Create attributes
        let attributes = TicketActivityAttributes(
            eventName: ticketWithEvent.event.name,
            venue: ticketWithEvent.event.venue,
            startTime: ticketWithEvent.event.startTime ?? Date(),
            endTime: ticketWithEvent.event.endTime
        )

        // Create content state
        let (timeString, hasStarted) = calculateTimeUntilEvent(
            startTime: ticketWithEvent.event.startTime ?? Date(),
            endTime: ticketWithEvent.event.endTime
        )
        let contentState = TicketActivityAttributes.ContentState(
            timeUntilEvent: timeString,
            hasEventStarted: hasStarted
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
            // Live activity start failed silently
        }
    }
    
    static func updateLiveActivity() {
        let activities = Activity<TicketActivityAttributes>.activities

        for activity in activities {
            let (timeString, hasStarted) = calculateTimeUntilEvent(
                startTime: activity.attributes.startTime,
                endTime: activity.attributes.endTime
            )
            let newContentState = TicketActivityAttributes.ContentState(
                timeUntilEvent: timeString,
                hasEventStarted: hasStarted
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
    
    private static func calculateTimeUntilEvent(startTime: Date, endTime: Date?) -> (String, Bool) {
        let now = Date()
        let calendar = Calendar.current

        // Check if event has started
        if startTime <= now {
            // Event has started - show countdown to end
            if let endTime = endTime, endTime > now {
                let components = calendar.dateComponents([.hour, .minute], from: now, to: endTime)
                if let hours = components.hour, let minutes = components.minute {
                    if hours > 0 {
                        return ("\(hours)h \(minutes)m", true)
                    } else {
                        return ("\(minutes)m", true)
                    }
                }
            }
            // Event has ended or no end time available
            return ("Event Ended", true)
        }

        // Event hasn't started yet - show countdown to start
        if calendar.isDate(startTime, inSameDayAs: now) {
            let components = calendar.dateComponents([.hour, .minute], from: now, to: startTime)
            if let hours = components.hour, let minutes = components.minute {
                if hours > 0 {
                    return ("\(hours)h \(minutes)m", false)
                } else {
                    return ("\(minutes)m", false)
                }
            }
        }

        let components = calendar.dateComponents([.day], from: now, to: startTime)
        if let days = components.day {
            if days == 0 {
                return ("Today", false)
            } else if days == 1 {
                return ("Tomorrow", false)
            } else {
                return ("\(days) days", false)
            }
        }

        return ("Soon", false)
    }
}
