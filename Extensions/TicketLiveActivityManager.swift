// MARK: - Live Activity Manager with Enhanced Debugging
// TicketLiveActivityManager.swift

import SwiftUI
import ActivityKit
import Foundation
import Combine

class TicketLiveActivityManager: ObservableObject {
    
    static func startLiveActivity(for ticketWithEvent: TicketWithEventData) {
        guard #available(iOS 16.1, *) else {
            print("❌ Live Activities not supported - iOS 16.1+ required")
            return
        }
        
        // Enhanced debugging
        print("🎫 Starting Live Activity for: \(ticketWithEvent.event.name)")
        print("📅 Event date: \(ticketWithEvent.event.date)")
        print("✅ Ticket status: \(ticketWithEvent.ticket.status)")
        
        // Check authorization
        let authInfo = ActivityAuthorizationInfo()
        print("🔐 Activities enabled: \(authInfo.areActivitiesEnabled)")
        
        if !authInfo.areActivitiesEnabled {
            print("❌ Live Activities are disabled by user")
            print("💡 User needs to enable in Settings → Face ID & Passcode → Live Activities")
            return
        }
        
        // Check if it's the event day or close to it
        let eventDate = ticketWithEvent.event.date
        let now = Date()
        let calendar = Calendar.current
        
        let isToday = calendar.isDate(eventDate, inSameDayAs: now)
        let isTomorrow = calendar.isDate(eventDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        
        print("📅 Is today: \(isToday), Is tomorrow: \(isTomorrow)")
        
        // Only start live activity if it's today or tomorrow and ticket is confirmed
        guard (isToday || isTomorrow) && ticketWithEvent.ticket.status == "confirmed" else {
            print("❌ Live Activity not started - event not today/tomorrow or ticket not confirmed")
            print("   Event date: \(eventDate)")
            print("   Current date: \(now)")
            print("   Is today/tomorrow: \(isToday || isTomorrow)")
            print("   Ticket status: \(ticketWithEvent.ticket.status)")
            return
        }
        
        // Check existing activities
        let existingActivities = Activity<TicketActivityAttributes>.activities
        print("📱 Current active Live Activities: \(existingActivities.count)")
        
        for (index, activity) in existingActivities.enumerated() {
            print("   Activity \(index): \(activity.attributes.eventName) - \(activity.id)")
        }
        
        // Check if there's already an active Live Activity for this event
        let existingActivity = existingActivities.first { activity in
            activity.attributes.eventName == ticketWithEvent.event.name &&
            calendar.isDate(activity.attributes.eventDate, inSameDayAs: eventDate)
        }
        
        if let existing = existingActivity {
            print("⚠️ Live Activity already exists for this event: \(existing.id)")
            return
        }
        
        // Generate QR code data
        let qrData = generateQRCodeData(for: ticketWithEvent)
        print("📱 Generated QR data length: \(qrData.count) characters")
        print("📱 QR data preview: \(String(qrData.prefix(50)))...")
        
        let attributes = TicketActivityAttributes(
            eventName: ticketWithEvent.event.name,
            venue: ticketWithEvent.event.venue,
            eventDate: eventDate,
            ticketNumber: ticketWithEvent.ticket.ticketNumber,
            qrCodeData: qrData,
            totalPrice: ticketWithEvent.ticket.totalPrice
        )
        
        let contentState = TicketActivityAttributes.ContentState(
            status: ticketWithEvent.ticket.status,
            timeUntilEvent: timeUntilEventString(eventDate: eventDate),
            isEventDay: isToday
        )
        
        print("📋 Attributes created:")
        print("   Event: \(attributes.eventName)")
        print("   Venue: \(attributes.venue)")
        print("   Date: \(attributes.eventDate)")
        print("   Ticket#: \(attributes.ticketNumber ?? "None")")
        print("   Price: £\(attributes.totalPrice)")
        
        print("📋 Content state:")
        print("   Status: \(contentState.status)")
        print("   Time until: \(contentState.timeUntilEvent ?? "None")")
        print("   Is event day: \(contentState.isEventDay)")
        
        do {
            let activity: Activity<TicketActivityAttributes>
            
            if #available(iOS 16.2, *) {
                print("🆕 Using iOS 16.2+ API with content parameter")
                activity = try Activity<TicketActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: nil
                )
            } else {
                print("🔄 Using iOS 16.1 API with contentState parameter")
                activity = try Activity<TicketActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            }
            
            print("✅ Live activity started successfully!")
            print("   ID: \(activity.id)")
            print("   State: \(activity.activityState)")
            print("   Push token: \(activity.pushToken?.description ?? "None")")
            
            // Check if it actually appears in activities list
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let allActivities = Activity<TicketActivityAttributes>.activities
                print("🔍 Post-creation check - Active activities: \(allActivities.count)")
                
                if allActivities.contains(where: { $0.id == activity.id }) {
                    print("✅ Activity confirmed in system list")
                } else {
                    print("❌ Activity NOT found in system list - this is the problem!")
                }
            }
            
        } catch {
            print("❌ Error starting live activity: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Localized description: \(error.localizedDescription)")
            
            // Check for common error conditions
            let errorDescription = error.localizedDescription.lowercased()
            
            if errorDescription.contains("disabled") {
                print("   → Live Activities are disabled")
                print("   → Enable in Settings → Face ID & Passcode → Live Activities")
            } else if errorDescription.contains("exceeded") || errorDescription.contains("limit") {
                print("   → Too many activities (iOS limit is 8 total)")
                print("   → Try ending some activities first")
            } else if errorDescription.contains("invalid") {
                print("   → Invalid attributes or content provided")
            } else if errorDescription.contains("authorization") {
                print("   → Authorization issue - check Live Activities permission")
            } else {
                print("   → Unexpected error - check iOS version and capabilities")
            }
            
            // Additional debugging info
            print("   → Current iOS: \(UIDevice.current.systemVersion)")
            if #available(iOS 16.1, *) {
                print("   → Auth status: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
                print("   → Current activities count: \(Activity<TicketActivityAttributes>.activities.count)")
            }
        }
    }
    
    @available(iOS 16.1, *)
    static func debugCurrentActivities() {
        let activities = Activity<TicketActivityAttributes>.activities
        print("🔍 DEBUG: Current Live Activities (\(activities.count)):")
        
        for (index, activity) in activities.enumerated() {
            print("   \(index + 1). \(activity.attributes.eventName)")
            print("      ID: \(activity.id)")
            print("      State: \(activity.activityState)")
            print("      Event Date: \(activity.attributes.eventDate)")
            
            // Use the content property for iOS 16.2+ or contentState for iOS 16.1
            if #available(iOS 16.2, *) {
                print("      Status: \(activity.content.state.status)")
                print("      Is Event Day: \(activity.content.state.isEventDay)")
            } else {
                print("      Status: \(activity.contentState.status)")
                print("      Is Event Day: \(activity.contentState.isEventDay)")
            }
            print("      ---")
        }
        
        if activities.isEmpty {
            print("   No active Live Activities found")
            
            // Check authorization again
            let authInfo = ActivityAuthorizationInfo()
            print("   Authorization status: \(authInfo.areActivitiesEnabled)")
        }
    }
    
    @available(iOS 16.1, *)
    static func updateLiveActivity() {
        let activities = Activity<TicketActivityAttributes>.activities
        print("🔄 Updating \(activities.count) Live Activities")
        
        Task {
            for activity in activities {
                let eventDate = activity.attributes.eventDate
                let now = Date()
                let calendar = Calendar.current
                
                // Check if event has passed
                if eventDate.addingTimeInterval(2 * 60 * 60) < now { // 2 hours after event
                    print("⏰ Ending expired activity: \(activity.attributes.eventName)")
                    
                    if #available(iOS 16.2, *) {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    } else {
                        await activity.end(using: nil, dismissalPolicy: .immediate)
                    }
                    continue
                }
                
                let newContentState = TicketActivityAttributes.ContentState(
                    status: "confirmed", // You might want to fetch this from your data source
                    timeUntilEvent: timeUntilEventString(eventDate: eventDate),
                    isEventDay: calendar.isDate(eventDate, inSameDayAs: now)
                )
                
                print("📝 Updating activity: \(activity.attributes.eventName)")
                print("   New time until: \(newContentState.timeUntilEvent ?? "None")")
                print("   Is event day: \(newContentState.isEventDay)")
                
                if #available(iOS 16.2, *) {
                    await activity.update(.init(state: newContentState, staleDate: nil))
                } else {
                    await activity.update(using: newContentState)
                }
            }
        }
    }
    
    @available(iOS 16.1, *)
    static func endLiveActivity() {
        let activities = Activity<TicketActivityAttributes>.activities
        print("🛑 Ending \(activities.count) Live Activities")
        
        Task {
            for activity in activities {
                print("   Ending: \(activity.attributes.eventName)")
                
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(using: nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
    
    private static func generateQRCodeData(for ticketWithEvent: TicketWithEventData) -> String {
        // Use existing QR code if available, otherwise generate new data
        if let existingQRCode = ticketWithEvent.ticket.qrCode, !existingQRCode.isEmpty {
            print("📱 Using existing QR code from ticket")
            return existingQRCode
        }
        
        print("📱 Generating new QR code data")
        
        // Generate QR code data based on your ticket structure
        let qrData: [String: Any] = [
            "ticketId": ticketWithEvent.ticket.id ?? "",
            "eventId": ticketWithEvent.ticket.eventId,
            "ticketNumber": ticketWithEvent.ticket.ticketNumber ?? "",
            "eventName": ticketWithEvent.event.name,
            "eventDate": ticketWithEvent.event.date.timeIntervalSince1970,
            "venue": ticketWithEvent.event.venue,
            "status": ticketWithEvent.ticket.status,
            "userId": ticketWithEvent.ticket.userId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: qrData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        // Fallback to ticket ID or a simple identifier
        let fallback = ticketWithEvent.ticket.id ?? "ticket-\(ticketWithEvent.ticket.eventId)"
        print("📱 Using fallback QR data: \(fallback)")
        return fallback
    }
    
    private static func timeUntilEventString(eventDate: Date) -> String? {
        let now = Date()
        let timeInterval = eventDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Event Started"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 24 {
            let days = hours / 24
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }
}
