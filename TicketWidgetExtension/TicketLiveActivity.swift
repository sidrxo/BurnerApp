import ActivityKit
import WidgetKit
import SwiftUI

struct TicketLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TicketActivityAttributes.self) { context in
            // Compact lock screen view
            VStack(spacing: 8) {
                Text(context.attributes.eventName)
                    .font(.custom("Avenir-Bold", size: 17))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(context.attributes.venue)
                    .font(.custom("Avenir-Regular", size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(context.state.timeUntilEvent)
                    .font(.custom("Avenir-Bold", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.white)

            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.attributes.eventName)
                            .font(.custom("Avenir-Bold", size: 15))
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                        
                        Text(context.attributes.venue)
                            .font(.custom("Avenir-Regular", size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 2) {
                        Text(context.state.timeUntilEvent)
                            .font(.custom("Avenir-Bold", size: 22))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("remaining")
                            .font(.custom("Avenir-Regular", size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                
            } compactLeading: {
                Text(context.state.timeUntilEvent)
                    .font(.custom("Avenir-Bold", size: 11))
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }


// MARK: - Preview Support
@available(iOS 16.1, *)
struct TicketLiveActivity_Previews: PreviewProvider {
    static let attributes = TicketActivityAttributes(
        eventName: "Stealth Hard Dance",
        venue: "Ministry of Sound",
        eventDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    )
    
    static let contentState = TicketActivityAttributes.ContentState(
        timeUntilEvent: "2h 15m"
    )
    
    static var previews: some View {
        Group {
            // Lock screen preview
            attributes
                .previewContext(contentState, viewKind: .content)
                .previewDisplayName("Lock Screen")
            
            // Dynamic Island expanded preview
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island - Expanded")
            
            // Dynamic Island compact preview
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Dynamic Island - Compact")
            
            // Dynamic Island minimal preview
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Dynamic Island - Minimal")
        }
    }
}

// Additional preview with different sample data
@available(iOS 16.1, *)
struct TicketLiveActivityVariations_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Event starting soon
            TicketActivityAttributes(
                eventName: "Ultra Music Festival",
                venue: "Bayfront Park",
                eventDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            )
            .previewContext(
                TicketActivityAttributes.ContentState(timeUntilEvent: "30m"),
                viewKind: .content
            )
            .previewDisplayName("Starting Soon")
            
         
            
            // Event started
            TicketActivityAttributes(
                eventName: "Coachella Valley Music Festival",
                venue: "Empire Polo Club",
                eventDate: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
            )
            .previewContext(
                TicketActivityAttributes.ContentState(timeUntilEvent: "Event Started"),
                viewKind: .content
            )
            .previewDisplayName("Event Started")
            
            // Long event name
            TicketActivityAttributes(
                eventName: "Electric Daisy Carnival Las Vegas 2025",
                venue: "Las Vegas Motor Speedway",
                eventDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
            )
            .previewContext(
                TicketActivityAttributes.ContentState(timeUntilEvent: "3 days"),
                viewKind: .dynamicIsland(.expanded)
            )
            .previewDisplayName("Long Name - Dynamic Island")
        }
    }
}
