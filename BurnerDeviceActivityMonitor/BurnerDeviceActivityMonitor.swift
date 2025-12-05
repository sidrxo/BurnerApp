//
//  BurnerDeviceActivityMonitor.swift
//  burner
//
//  Created by Sid Rao on 11/11/2025.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import SwiftUI

class BurnerDeviceActivityMonitor: DeviceActivityMonitor {

    // Lazy initialization to reduce startup warnings
    private lazy var appGroupDefaults: UserDefaults? = {
        UserDefaults(suiteName: "group.com.gas.Burner")
    }()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        print("🔒 Burner Mode interval started: \(activity)")

        // Reapply restrictions when interval starts
        let store = ManagedSettingsStore()

        // Check if burner mode should be active
        let isEnabled = appGroupDefaults?.bool(forKey: "burnerModeEnabled") ?? false

        if isEnabled {
            reapplyRestrictions(store: store)
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        print("🔓 Burner Mode interval ended: \(activity)")
        
        // This is called when the event end time is reached
        // The app does NOT need to be open for this to execute
        
        if activity == DeviceActivityName("burner.protection") {
            let store = ManagedSettingsStore()
            
            // Clear all Screen Time restrictions
            store.clearAllSettings()
            
            // Update the state in App Group UserDefaults
            appGroupDefaults?.set(false, forKey: "burnerModeEnabled")
            
            // Clean up stored end time
            appGroupDefaults?.removeObject(forKey: "burnerModeEventEndTime")
            
            print("✓ Burner Mode automatically disabled - restrictions cleared")
            
            // The notification will be delivered by iOS at the scheduled time
            // No need to handle it here
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("⚠️ Event threshold reached: \(event) for activity: \(activity)")
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        print("⏰ Burner Mode interval will start soon: \(activity)")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        print("⏰ Burner Mode interval will end soon: \(activity)")
        
        // This is called 5 minutes before the interval ends
        // You could optionally schedule a warning notification here
    }
    
    private func reapplyRestrictions(store: ManagedSettingsStore) {
        // Load saved selection from shared UserDefaults
        guard let data = appGroupDefaults?.data(forKey: "selectedApps"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            // If no selection, block everything
            store.shield.applicationCategories = .all()
            store.application.denyAppRemoval = true
            return
        }

        // Reapply the same restrictions
        if selection.applicationTokens.isEmpty {
            store.shield.applicationCategories = .all()
        } else {
            store.shield.applicationCategories = .all(except: selection.applicationTokens)
        }

        // CRITICAL: Block Settings app to prevent uninstallation
        store.application.denyAppRemoval = true
        
        print("✓ Restrictions reapplied: \(selection.applicationTokens.count) apps whitelisted")
    }
}
