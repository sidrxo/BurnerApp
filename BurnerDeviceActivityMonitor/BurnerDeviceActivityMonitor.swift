//
//  BurnerDeviceActivityMonitor.swift
//  burner
//
//  Created by Sid Rao on 11/11/2025.
//


// DeviceActivityMonitor.swift (in your extension target)
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
        // Keep restrictions active - don't disable automatically
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
    }
    
    private func reapplyRestrictions(store: ManagedSettingsStore) {
        // Load saved selection from shared UserDefaults
        guard let data = appGroupDefaults?.data(forKey: "selectedApps"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            // If no selection, block everything
            store.shield.applicationCategories = .all()
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
    }
}
