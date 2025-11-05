import ActivityKit
import WidgetKit
import SwiftUI

struct TicketLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TicketActivityAttributes.self) { context in
            // Compact lock screen view
            if context.state.hasEventStarted {
                // Centered countdown when event has started
                VStack(spacing: 4) {
                    Text(context.state.timeUntilEvent)
                        .font(.custom("HelveticaNeue", size: 28).weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("until event ends")
                        .font(.custom("HelveticaNeue", size: 12).weight(.regular))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(Color.white)
            } else {
                // Standard layout before event starts
                HStack(spacing: 12) {
                    // Left side - Event info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.eventName)
                            .font(.custom("HelveticaNeue", size: 13).weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(context.attributes.venue)
                            .font(.custom("HelveticaNeue", size: 11).weight(.regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    // Right side - Timer
                    Text(context.state.timeUntilEvent)
                        .font(.custom("HelveticaNeue", size: 16).weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(minWidth: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(Color.white)
            }
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.attributes.eventName)
                            .font(.custom("HelveticaNeue", size: 15).weight(.heavy))
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                        
                        Text(context.attributes.venue)
                            .font(.custom("HelveticaNeue", size: 12).weight(.regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 2) {
                        Text(context.state.timeUntilEvent)
                            .font(.custom("HelveticaNeue", size: 22).weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)

                        Text(context.state.hasEventStarted ? "until end" : "remaining")
                            .font(.custom("HelveticaNeue", size: 12).weight(.regular))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
            } compactLeading: {
                Text(context.state.timeUntilEvent)
                    .font(.custom("HelveticaNeue", size: 14).weight(.bold))
                    .foregroundColor(.white)
            } compactTrailing: {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Preview Support
@available(iOS 16.1, *)
struct TicketLiveActivity_Previews: PreviewProvider {
    static let attributesBeforeStart = TicketActivityAttributes(
        eventName: "RESISTANCE LONDON SATURDAY",
        venue: "DRUMSHEDS",
        startTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
    )

    static let attributesAfterStart = TicketActivityAttributes(
        eventName: "RESISTANCE LONDON SATURDAY",
        venue: "DRUMSHEDS",
        startTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
    )

    static let contentStateBeforeStart = TicketActivityAttributes.ContentState(
        timeUntilEvent: "2h 15m",
        hasEventStarted: false
    )

    static let contentStateAfterStart = TicketActivityAttributes.ContentState(
        timeUntilEvent: "3h 45m",
        hasEventStarted: true
    )

    static var previews: some View {
        Group {
            attributesBeforeStart
                .previewContext(contentStateBeforeStart, viewKind: .content)
                .previewDisplayName("Lock Screen - Before Start")

            attributesAfterStart
                .previewContext(contentStateAfterStart, viewKind: .content)
                .previewDisplayName("Lock Screen - Event Started")

            attributesBeforeStart
                .previewContext(contentStateBeforeStart, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island - Expanded")

            attributesBeforeStart
                .previewContext(contentStateBeforeStart, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Dynamic Island - Compact")
        }
    }
}
