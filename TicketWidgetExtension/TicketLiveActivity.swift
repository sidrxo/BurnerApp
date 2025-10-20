import ActivityKit
import WidgetKit
import SwiftUI

struct TicketLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TicketActivityAttributes.self) { context in
            // Compact lock screen view
            HStack(spacing: 0) {
                // Left side - Event info
                VStack(alignment: .leading, spacing: 6) {
                    Text(context.attributes.eventName)
                        .appBody()
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(context.attributes.venue)
                        .appSecondary()
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 12)
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                // Right side - Timer
                Text(context.state.timeUntilEvent)
                    .appPageHeader()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.white)
            
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
                        
                        Text("remaining")
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
    static let attributes = TicketActivityAttributes(
        eventName: "RESISTANCE LONDON SATURDAY",
        venue: "DRUMSHEDS",
        startTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    )
    
    static let contentState = TicketActivityAttributes.ContentState(
        timeUntilEvent: "02:15:00"
    )
    
    static var previews: some View {
        Group {
            attributes
                .previewContext(contentState, viewKind: .content)
                .previewDisplayName("Lock Screen")
            
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island - Expanded")
            
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Dynamic Island - Compact")
            
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Dynamic Island - Minimal")
        }
    }
}
