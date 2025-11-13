import ActivityKit
import WidgetKit
import SwiftUI

struct TicketLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TicketActivityAttributes.self) { context in
            // LOCK SCREEN VIEW
            ZStack {
                VStack(spacing: 0) {
                    // Determine which layout to show
                    let hasStarted = context.state.hasEventStarted
                    
                    if hasStarted {
                        // DURING EVENT: Time until end + event info + progress bar
                        VStack(spacing: 0) {
                            // Time countdown (large, italic) - updates every minute
                            if let eventEndTime = context.state.eventEndTime {
                                TimelineView(.periodic(from: Date(), by: 60)) { timeContext in
                                    Text(formatTimeRemaining(until: eventEndTime, at: timeContext.date))
                                        .font(.custom("Avenir Next", size: 52).italic().weight(.heavy))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .monospacedDigit()
                                }
                            }
                            
                            // Progress bar section - auto-updating with ProgressView
                            if let eventEndTime = context.state.eventEndTime {
                                ProgressView(
                                    timerInterval: context.state.eventStartTime...eventEndTime,
                                    countsDown: false
                                ) {
                                    EmptyView()
                                } currentValueLabel: {
                                    EmptyView()
                                }
                                .progressViewStyle(.linear)
                                .tint(.black)
                                .frame(height: 6)
                                .padding(.horizontal, 20)
                                .padding(.top, -8)
                                .padding(.bottom, 10)
                            }
                        
                            HStack(spacing: 0) {
                                // Event name
                                Text(context.attributes.eventName)
                                    .font(.custom("Avenir Next", size: 16))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                // Separator dot (centered)
                                HStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(width: 4, height: 4)
                                }
                                .frame(width: 16)

                                // Venue
                                Text(context.attributes.venue)
                                    .font(.custom("Avenir Next", size: 16))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity)

                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                        
                    } else {
                        // BEFORE EVENT STARTS: Show event time + event info
                        VStack(spacing: 0) {
                            // Event time (large, italic)
                            Text(formatEventTime(context.attributes.startTime))
                                .font(.custom("Avenir Next", size: 52).italic().weight(.heavy))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            // "DOORS OPEN" text
                            Text("DOORS OPEN")
                                .font(.custom("Avenir Next", size: 11).weight(.medium))
                                .foregroundColor(.black.opacity(0.6))
                                .tracking(1)
                                .padding(.top, -8)
                                .padding(.bottom, 10)
                        
                            HStack(spacing: 0) {
                                // Event name
                                Text(context.attributes.eventName)
                                    .font(.custom("Avenir Next", size: 16))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                // Separator dot (centered)
                                HStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(width: 4, height: 4)
                                }
                                .frame(width: 16)

                                // Venue
                                Text(context.attributes.venue)
                                    .font(.custom("Avenir Next", size: 16))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity)

                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.white)
            .activityBackgroundTint(Color.white)
            .activitySystemActionForegroundColor(Color.black)
            .widgetURL(URL(string: "burner://ticket/\(context.attributes.ticketId)"))

        } dynamicIsland: { context in
            // DYNAMIC ISLAND: clock icon + time only
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .imageScale(.medium)

                        // Time until start or until end
                        if context.state.hasEventStarted, let end = context.state.eventEndTime {
                            TimelineView(.periodic(from: Date(), by: 60)) { timeContext in
                                Text(formatTimeRemaining(until: end, at: timeContext.date))
                                    .font(.headline.monospacedDigit())
                            }
                        } else {
                            TimelineView(.periodic(from: Date(), by: 60)) { timeContext in
                                Text(formatTimeRemaining(until: context.state.eventStartTime, at: timeContext.date))
                                    .font(.headline.monospacedDigit())
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "clock")
                    .imageScale(.small)
            } compactTrailing: {
                if context.state.hasEventStarted, let end = context.state.eventEndTime {
                    TimelineView(.periodic(from: Date(), by: 60)) { timeContext in
                        Text(formatTimeRemaining(until: end, at: timeContext.date))
                            .font(.caption2.monospacedDigit())
                    }
                } else {
                    TimelineView(.periodic(from: Date(), by: 60)) { timeContext in
                        Text(formatTimeRemaining(until: context.state.eventStartTime, at: timeContext.date))
                            .font(.caption2.monospacedDigit())
                    }
                }
            } minimal: {
                Image(systemName: "clock")
                    .imageScale(.small)
            }
        }
    }
}

// MARK: - Helper Functions
func formatEventTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter.string(from: date)
}

func formatTimeRemaining(until endDate: Date, at currentDate: Date) -> String {
    let timeInterval = endDate.timeIntervalSince(currentDate)
    
    // If time has passed, show "0h 0m"
    guard timeInterval > 0 else {
        return "0h 0m"
    }
    
    let hours = Int(timeInterval) / 3600
    let minutes = (Int(timeInterval) % 3600) / 60
    
    return "\(hours)h \(minutes)m"
}

// MARK: - Preview Support
@available(iOS 16.1, *)
struct TicketLiveActivity_Previews: PreviewProvider {
    static let attributesMoreThanOneHour = TicketActivityAttributes(
        eventName: "Garage Classics",
        venue: "Ministry of Sound",
        startTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date(),
        ticketId: "preview-ticket-id"
    )

    static let attributesDuringEvent = TicketActivityAttributes(
        eventName: "Garage Classics",
        venue: "Ministry of Sound",
        startTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
        ticketId: "preview-ticket-id"
    )

    static let contentStateMoreThanOneHour = TicketActivityAttributes.ContentState(
        eventStartTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
        eventEndTime: Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date(),
        hasEventStarted: false,
        hasEventEnded: false,
    )

    static let contentStateDuringEvent = TicketActivityAttributes.ContentState(
        eventStartTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
        eventEndTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
        hasEventStarted: true,
        hasEventEnded: false,
    )

    static var previews: some View {
        Group {
            // State 1: Before event starts - Show event time
            attributesMoreThanOneHour
                .previewContext(contentStateMoreThanOneHour, viewKind: .content)
                .previewDisplayName("Lock Screen - Before Event")

            // State 2: Event started - Show countdown with progress
            attributesDuringEvent
                .previewContext(contentStateDuringEvent, viewKind: .content)
                .previewDisplayName("Lock Screen - Event Started")

            // Optional: Dynamic Island previews
            attributesMoreThanOneHour
                .previewContext(contentStateMoreThanOneHour, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Island - Compact (Before)")

            attributesDuringEvent
                .previewContext(contentStateDuringEvent, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Island - Compact (During)")

            attributesMoreThanOneHour
                .previewContext(contentStateMoreThanOneHour, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Island - Minimal")
        }
    }
}
