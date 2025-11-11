import Swift
import Foundation
import FamilyControls
import ManagedSettings
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
    private var authorizationCancellable: AnyCancellable?
    
    // All possible categories that exist in iOS
    // This is a comprehensive list - adjust based on what you want to require
    private let allRequiredCategories = [
        "Social", "Games", "Entertainment", "Creativity", "Productivity",
        "Education", "Utilities", "Business", "Developer Tools", "Graphics & Design",
        "Lifestyle", "Music", "News", "Photo & Video", "Shopping",
        "Sports", "Travel", "Health & Fitness", "Food & Drink", "Finance",
        "Weather", "Reference", "Navigation", "Medical", "Books"
    ]
    
    let minimumCategoriesRequired = 8 // Must select 8+ categories
    
    init() {
        loadSelectedApps()
        setupAuthorizationMonitoring()
        checkSetupCompliance()
    }
    
    private func setupAuthorizationMonitoring() {
        // Monitor authorization status changes
        authorizationCancellable = AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isAuthorized = (status == .approved)
                self?.checkSetupCompliance()
            }
        
        // Initial check
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    func hasAllCategoriesSelected() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        return categoryCount >= minimumCategoriesRequired
    }
   
    @discardableResult
    func checkSetupCompliance() -> Bool {
        // First check authorization
        guard isAuthorized else {
            setupError = "Screen Time permission required"
            isSetupValid = false
            return false
        }
        
        let categoryCount = selectedApps.categoryTokens.count
        
        // Require all categories to be selected
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
        if let data = UserDefaults.standard.data(forKey: "selectedApps"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = selection
        }
    }
    
    private func saveSelectedApps() {
        if let data = try? JSONEncoder().encode(selectedApps) {
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
        
        // Block ALL categories except the selected apps (if any)
        if selectedApps.applicationTokens.isEmpty {
            // Block everything - no exceptions
            store.shield.applicationCategories = .all()
        } else {
            // Block all except selected apps
            store.shield.applicationCategories = .all(except: selectedApps.applicationTokens)
        }

        UserDefaults.standard.set(true, forKey: "burnerModeEnabled")
    }

    func disable() {
        guard isAuthorized else {
            return
        }

        store.clearAllSettings()
        UserDefaults.standard.set(false, forKey: "burnerModeEnabled")
    }
    
    func clearAllSelections() {
        selectedApps = FamilyActivitySelection()
        UserDefaults.standard.removeObject(forKey: "selectedApps")
    }
    
    var isSetup: Bool {
        // Consider burner mode set up if:
        // 1. Screen Time is authorized
        // 2. There are enough categories selected
        // 3. The setup is valid
        // 4. The selection has been saved
        return isAuthorized &&
               isSetupValid &&
               hasAllCategoriesSelected() &&
               UserDefaults.standard.data(forKey: "selectedApps") != nil
    }
}

enum BurnerModeError: Error {
    case notAuthorized
    case invalidSetup(String)
}
