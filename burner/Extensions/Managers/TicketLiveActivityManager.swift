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
            endTime: ticketWithEvent.event.endTime,
            ticketId: ticketWithEvent.ticket.id ?? ""
        )

        // Create content state with dates (no need for progress - ProgressView handles it)
        let startTime = ticketWithEvent.event.startTime ?? Date()
        let endTime = ticketWithEvent.event.endTime
        let now = Date()
        let hasStarted = now >= startTime
        let hasEnded = endTime != nil ? now >= endTime! : false

        let contentState = TicketActivityAttributes.ContentState(
            eventStartTime: startTime,
            eventEndTime: endTime,
            hasEventStarted: hasStarted,
            hasEventEnded: hasEnded
        )

        do {
            // Set stale date for automatic updates
            let staleDate = calculateNextStaleDate(startTime: startTime, endTime: endTime)

            if #available(iOS 16.2, *) {
                _ = try Activity<TicketActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: staleDate),
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
            let startTime = activity.attributes.startTime
            let endTime = activity.attributes.endTime
            let now = Date()
            let hasStarted = now >= startTime
            let hasEnded = endTime != nil ? now >= endTime! : false

            // End the activity if the event has ended
            if hasEnded {
                Task {
                    if #available(iOS 16.2, *) {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    } else {
                        await activity.end(dismissalPolicy: .immediate)
                    }
                }
                continue
            }

            let newContentState = TicketActivityAttributes.ContentState(
                eventStartTime: startTime,
                eventEndTime: endTime,
                hasEventStarted: hasStarted,
                hasEventEnded: hasEnded
            )

            Task {
                // Set stale date for next automatic update
                let staleDate = calculateNextStaleDate(startTime: startTime, endTime: endTime)

                if #available(iOS 16.2, *) {
                    await activity.update(.init(state: newContentState, staleDate: staleDate))
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
    
    // Calculate when the activity should be marked as stale for iOS to update it
    private static func calculateNextStaleDate(startTime: Date, endTime: Date?) -> Date? {
        let now = Date()
        let oneHourBeforeStart = Calendar.current.date(byAdding: .hour, value: -1, to: startTime) ?? startTime

        // If we're more than 1 hour away, mark stale when we hit the 1-hour mark
        if now < oneHourBeforeStart {
            return oneHourBeforeStart
        }

        // If we're less than 1 hour away but event hasn't started, mark stale at event start
        if now < startTime {
            return startTime
        }

        // If event has started and we have an end time, mark stale at end time
        if let endTime = endTime, now < endTime {
            return endTime
        }

        // Event has ended or no end time - no more updates needed
        return nil
    }
}
