//
//  TicketActivityAttributes.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//


//
//  TicketActivityAttributes.swift
//  Shared between app and widget extension
//
//  Created by Sid Rao on 19/09/2025.
//

import Foundation

// Only import ActivityKit if iOS 16.1+
#if canImport(ActivityKit)
import ActivityKit

// MARK: - Activity Attributes (iOS 16.1+)
@available(iOS 16.1, *)
struct TicketActivityAttributes: ActivityAttributes {
    public typealias TicketStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        // Dynamic properties that can change during the live activity
        var status: String
        var timeUntilEvent: String?
        var isEventDay: Bool
    }
    
    // Static properties that don't change during the activity
    var eventName: String
    var venue: String
    var eventDate: Date
    var ticketNumber: String?
    var qrCodeData: String
    var totalPrice: Double
}
#endif