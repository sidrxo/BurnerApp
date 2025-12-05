//
//  NotificationDelegate.swift
//  burner
//
//  Created by Sid Rao on 05/12/2025.
//


import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    // Called when a notification is delivered while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        _ = notification.request.identifier
        
        // Always show notifications even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // Called when user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        // Handle notification tap based on identifier
        if identifier == "burner-mode-event-ended" {
            // User tapped on event ended notification
            // Could navigate to tickets or home screen
            NotificationCenter.default.post(
                name: NSNotification.Name("UserTappedEventEndedNotification"),
                object: nil
            )
        }
        
        completionHandler()
    }
}
