import Swift
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

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
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private var authorizationCancellable: AnyCancellable?
    
    // App Group for sharing data with extension
    private let appGroupDefaults = UserDefaults(suiteName: "group.com.gas.Burner")
    
    let minimumCategoriesRequired = 8
    
    init() {
        loadSelectedApps()
        setupAuthorizationMonitoring()
        checkSetupCompliance()
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
    
    func enable() async throws {
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
    }
    
    func clearAllSelections() {
        selectedApps = FamilyActivitySelection()
        appGroupDefaults?.removeObject(forKey: "selectedApps")
        UserDefaults.standard.removeObject(forKey: "selectedApps")
    }
    
    var isSetup: Bool {
        return isAuthorized &&
               isSetupValid &&
               hasAllCategoriesSelected() &&
               (appGroupDefaults?.data(forKey: "selectedApps") != nil ||
                UserDefaults.standard.data(forKey: "selectedApps") != nil)
    }
}

enum BurnerModeError: Error {
    case notAuthorized
    case invalidSetup(String)
}
