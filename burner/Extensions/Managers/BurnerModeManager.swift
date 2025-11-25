import Swift
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import UserNotifications

@MainActor
class BurnerModeManager: ObservableObject {
    @Published var selectedApps = FamilyActivitySelection() {
        didSet {
            saveSelectedApps()
            checkSetupCompliance()
        }
    }
    @Published var isSetupValid = false
    @Published var setupError: String?
    @Published var isAuthorized = false
    @Published var hasCompletedSetup: Bool = false
    @Published var isLocked: Bool = false
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private var authorizationCancellable: AnyCancellable?
    
    // App Group for sharing data with extension
    private let appGroupDefaults = UserDefaults(suiteName: "group.com.yourapp.burner")
    
    // NFC Manager for unlock functionality
    let nfcManager = NFCUnlockManager()
    
    let minimumCategoriesRequired = 8
    
    init() {
        loadSelectedApps()
        loadHasCompletedSetup()
        setupAuthorizationMonitoring()
        checkSetupCompliance()
    }

    private func loadHasCompletedSetup() {
        hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedBurnerSetup")
    }
    
    private func setupAuthorizationMonitoring() {
        authorizationCancellable = AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isAuthorized = (status == .approved)
                self?.checkSetupCompliance()
            }
        
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    func hasAllCategoriesSelected() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        return categoryCount >= minimumCategoriesRequired
    }
   
    @discardableResult
    func checkSetupCompliance() -> Bool {
        guard isAuthorized else {
            setupError = "Screen Time permission required"
            isSetupValid = false
            return false
        }
        
        let categoryCount = selectedApps.categoryTokens.count
        
        if categoryCount < minimumCategoriesRequired {
            setupError = "Please select more categories."
            isSetupValid = false
            return false
        }
        
        setupError = nil
        isSetupValid = true
        return true
    }
    
    func getSetupValidationMessage() -> String {
        if !isAuthorized {
            return "⚠️ Screen Time permission required"
        }
        
        if isSetupValid {
            return "✓ Ready for Block-All Mode"
        } else {
            return setupError ?? "Setup incomplete"
        }
    }
    
    func getSelectedAppsDescription() -> String {
        if !isAuthorized {
            return "Enable Screen Time permissions to continue"
        }
        
        let appCount = selectedApps.applicationTokens.count
        let categoryCount = selectedApps.categoryTokens.count
        
        if hasAllCategoriesSelected() {
            return appCount > 0 ? "\(appCount) apps will stay available" : "All apps will be blocked"
        } else if categoryCount > 0 {
            return "\(categoryCount) categories selected - Need \(minimumCategoriesRequired) total"
        } else {
            return "Select \(minimumCategoriesRequired) categories to enable block-all mode"
        }
    }
    
    private func loadSelectedApps() {
        // Try app group first, fall back to standard UserDefaults
        if let data = appGroupDefaults?.data(forKey: "selectedApps") ?? UserDefaults.standard.data(forKey: "selectedApps"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = selection
        }
    }
    
    private func saveSelectedApps() {
        if let data = try? JSONEncoder().encode(selectedApps) {
            // Save to both locations
            appGroupDefaults?.set(data, forKey: "selectedApps")
            UserDefaults.standard.set(data, forKey: "selectedApps")
        }
    }

    // MARK: - Check Authorization
    func checkAuthorization() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        checkSetupCompliance()
    }

    // MARK: - Complete Setup
    func completeSetup() {
        hasCompletedSetup = true
        UserDefaults.standard.set(true, forKey: "hasCompletedBurnerSetup")

        // Cancel all pending setup reminder notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let setupReminderIDs = requests
                .filter { $0.identifier.starts(with: "setup-reminder-") }
                .map { $0.identifier }

            if !setupReminderIDs.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: setupReminderIDs)
                print("🔔 Cancelled \(setupReminderIDs.count) setup reminder notifications")
            }
        }

        print("✅ Burner Mode setup completed")
    }

    // MARK: - Reset Setup
    func resetSetup() {
        hasCompletedSetup = false
        UserDefaults.standard.set(false, forKey: "hasCompletedBurnerSetup")
        print("🔄 Burner Mode setup reset")
    }

    func enable(appState: AppState) async throws {
        guard isAuthorized else {
            throw BurnerModeError.notAuthorized
        }
        
        guard isSetupValid else {
            throw BurnerModeError.invalidSetup("Must select at least \(minimumCategoriesRequired) categories first")
        }
        
        guard hasAllCategoriesSelected() else {
            throw BurnerModeError.invalidSetup("Not enough categories selected")
        }

        // Request authorization
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        
        // DETERMINE AND SET END TIME ONCE when enabling burner mode
        let eventEndTime = await calculateEventEndTime(appState: appState)
        UserDefaults.standard.set(eventEndTime, forKey: "burnerModeEventEndTime")
        UserDefaults.standard.set(false, forKey: "burnerModeTerminalShown") // Reset terminal flag
        
        // CRITICAL SECURITY MEASURES
        
        // 1. Block app removal (prevents uninstallation)
        store.application.denyAppRemoval = true
        
        // 2. Apply shields to apps
        if selectedApps.applicationTokens.isEmpty {
            store.shield.applicationCategories = .all()
        } else {
            store.shield.applicationCategories = .all(except: selectedApps.applicationTokens)
        }
        
        // 3. Start Device Activity monitoring to reapply restrictions
        try startDeviceActivityMonitoring()

        // Save state to both UserDefaults locations
        appGroupDefaults?.set(true, forKey: "burnerModeEnabled")
        UserDefaults.standard.set(true, forKey: "burnerModeEnabled")

        // Update locked state
        isLocked = true
    }
    
    private func calculateEventEndTime(appState: AppState) async -> Date {
        // 24-HOUR ROLLING WINDOW: Find tickets scanned in last 24 hours
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 3600)
        
        let recentScannedTicket = appState.ticketsViewModel.tickets.first { ticket in
            guard ticket.status == "used",
                  let usedAt = ticket.usedAt else {
                return false
            }
            // Check if scanned within last 24 hours
            return usedAt >= twentyFourHoursAgo
        }
        
        // If we found a recent scanned ticket, fetch the event to get the end time
        if let ticket = recentScannedTicket {
            do {
                let event = try await appState.eventViewModel.fetchEvent(byId: ticket.eventId)
                
                if let endTime = event.endTime {
                    // Use actual event end time with timezone awareness
                    let calendar = Calendar.current
                    let timeZone = calendar.timeZone
                    let components = calendar.dateComponents(in: timeZone, from: endTime)
                    if let adjustedEndTime = calendar.date(from: components) {
                        return adjustedEndTime
                    } else {
                        return endTime
                    }
                } else {
                    // Fallback: Use start time + 4 hours if no end time
                    return ticket.startTime.addingTimeInterval(4 * 3600)
                }
            } catch {
                // If fetching event fails, use ticket start time + 4 hours as fallback
                return ticket.startTime.addingTimeInterval(4 * 3600)
            }
        } else {
            // If no recent scanned ticket found, use a default fallback
            return Date().addingTimeInterval(4 * 3600)
        }
    }
    
    private func startDeviceActivityMonitoring() throws {
        // Create a schedule that runs all day, every day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("burner.protection")
        
        do {
            try center.startMonitoring(activityName, during: schedule)
            print("✅ Device Activity monitoring started")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
            throw error
        }
    }

    func disable() {
        guard isAuthorized else {
            return
        }

        // Stop device activity monitoring
        let activityName = DeviceActivityName("burner.protection")
        center.stopMonitoring([activityName])

        // Clear all restrictions
        store.clearAllSettings()

        // Update state in both locations
        appGroupDefaults?.set(false, forKey: "burnerModeEnabled")
        UserDefaults.standard.set(false, forKey: "burnerModeEnabled")

        // Clean up end time and terminal flag
        UserDefaults.standard.removeObject(forKey: "burnerModeEventEndTime")
        UserDefaults.standard.removeObject(forKey: "burnerModeTerminalShown")

        // Update locked state
        isLocked = false
    }
    
    func clearAllSelections() {
        selectedApps = FamilyActivitySelection()
        appGroupDefaults?.removeObject(forKey: "selectedApps")
        UserDefaults.standard.removeObject(forKey: "selectedApps")
    }
    
    // MARK: - NFC Unlock
    func unlockWithNFC() {
        guard isLocked else { return }
        disable()
    }
}

enum BurnerModeError: Error {
    case notAuthorized
    case invalidSetup(String)
}
