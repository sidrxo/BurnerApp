import ActivityKit
import WidgetKit
import SwiftUI

struct TicketLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TicketActivityAttributes.self) { context in
            // Compact lock screen view - Nike run tracker style
            ZStack(alignment: .center) {
                VStack(spacing: 0) {
                    // Determine which layout to show
                    let oneHourBeforeStart = Calendar.current.date(byAdding: .hour, value: -1, to: context.attributes.startTime) ?? context.attributes.startTime
                    let isMoreThanOneHourAway = Date() < oneHourBeforeStart
                    let hasStarted = context.state.hasEventStarted
                    
                    if hasStarted {
                        // DURING EVENT: Time until end + progress bar + event info
                        VStack(spacing: 8) {
                            // Time countdown (large, italic) - automatic timer (updates every minute)
                            if let eventEndTime = context.state.eventEndTime {
                                Text(eventEndTime, style: .relative)
                                    .font(.custom("Avenir Next", size: 52).italic().weight(.heavy))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .monospacedDigit()
                            }

                            // Event name
                            Text(context.attributes.eventName)
                                .font(.custom("Avenir Next", size: 14).weight(.semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            // Venue
                            Text(context.attributes.venue)
                                .font(.custom("Avenir Next", size: 11).weight(.regular))
                                .foregroundColor(.black.opacity(0.6))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        
                        // Progress bar section
                        VStack(spacing: 0) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background bar
                                    Rectangle()
                                        .fill(Color.black.opacity(0.15))
                                        .frame(height: 6)
                                    
                                    // Filled progress bar
                                    Rectangle()
                                        .fill(Color.black)
                                        .frame(width: geometry.size.width * context.state.progress, height: 6)
                                    
                                    // Progress circle indicator
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 14, height: 14)
                                        .offset(x: (geometry.size.width * context.state.progress) - 7)
                                }
                            }
                            .frame(height: 14)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                    } else if isMoreThanOneHourAway {
                        // MORE THAN 1 HOUR AWAY: Show event time + event info
                        VStack(spacing: 8) {
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
                            
                            // Event name
                            Text(context.attributes.eventName)
                                .font(.custom("Avenir Next", size: 14).weight(.semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            // Venue
                            Text(context.attributes.venue)
                                .font(.custom("Avenir Next", size: 11).weight(.regular))
                                .foregroundColor(.black.opacity(0.6))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        // LESS THAN 1 HOUR AWAY: Show countdown + QR code icon (no event info)
                        VStack(spacing: 8) {
                            // QR code icon above
                            Image(systemName: "qrcode")
                                .font(.system(size: 28, weight: .regular))
                                .foregroundColor(.black)

                            // Countdown (large, italic) - automatic timer (updates every minute)
                            Text(context.state.eventStartTime, style: .relative)
                                .font(.custom("Avenir Next", size: 52).italic().weight(.heavy))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .monospacedDigit()

                            // "DOORS OPEN" text
                            Text("DOORS OPEN")
                                .font(.custom("Avenir Next", size: 11).weight(.medium))
                                .foregroundColor(.black.opacity(0.6))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .activityBackgroundTint(Color.white)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }

            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
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

// MARK: - Preview Support
@available(iOS 16.1, *)
struct TicketLiveActivity_Previews: PreviewProvider {
    static let attributesMoreThanOneHour = TicketActivityAttributes(
        eventName: "Garage Classics",
        venue: "Ministry of Sound",
        startTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
    )
    
    static let attributesLessThanOneHour = TicketActivityAttributes(
        eventName: "Garage Classics",
        venue: "Ministry of Sound",
        startTime: Calendar.current.date(byAdding: .minute, value: 45, to: Date()) ?? Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 5, to: Date()) ?? Date()
    )

    static let attributesDuringEvent = TicketActivityAttributes(
        eventName: "Garage Classics",
        venue: "Ministry of Sound",
        startTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
    )

    static let contentStateMoreThanOneHour = TicketActivityAttributes.ContentState(
        eventStartTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
        eventEndTime: Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date(),
        hasEventStarted: false,
        hasEventEnded: false,
        progress: 0.0
    )

    static let contentStateLessThanOneHour = TicketActivityAttributes.ContentState(
        eventStartTime: Calendar.current.date(byAdding: .minute, value: 45, to: Date()) ?? Date(),
        eventEndTime: Calendar.current.date(byAdding: .hour, value: 5, to: Date()) ?? Date(),
        hasEventStarted: false,
        hasEventEnded: false,
        progress: 0.0
    )

    static let contentStateDuringEvent = TicketActivityAttributes.ContentState(
        eventStartTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
        eventEndTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
        hasEventStarted: true,
        hasEventEnded: false,
        progress: 0.35
    )

    static var previews: some View {
        Group {
            // State 1: More than 1 hour away - Show event time
            attributesMoreThanOneHour
                .previewContext(contentStateMoreThanOneHour, viewKind: .content)
                .previewDisplayName("Lock Screen - Event Time (>1hr)")

            // State 2: Less than 1 hour away - Show countdown with QR code
            attributesLessThanOneHour
                .previewContext(contentStateLessThanOneHour, viewKind: .content)
                .previewDisplayName("Lock Screen - Countdown + QR (<1hr)")

            // State 3: Event started - Show countdown with progress
            attributesDuringEvent
                .previewContext(contentStateDuringEvent, viewKind: .content)
                .previewDisplayName("Lock Screen - Event Started")

            attributesMoreThanOneHour
                .previewContext(contentStateMoreThanOneHour, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island - Expanded (Before)")

            attributesDuringEvent
                .previewContext(contentStateDuringEvent, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island - Expanded (During)")

            attributesLessThanOneHour
                .previewContext(contentStateLessThanOneHour, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Dynamic Island - Compact")
        }
    }
}
