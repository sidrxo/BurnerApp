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
    
    private let store = ManagedSettingsStore()
    
    // All possible categories that exist in iOS
    // This is a comprehensive list - adjust based on what you want to require
    private let allRequiredCategories = [
        "Social", "Games", "Entertainment", "Creativity", "Productivity",
        "Education", "Utilities", "Business", "Developer Tools", "Graphics & Design",
        "Lifestyle", "Music", "News", "Photo & Video", "Shopping",
        "Sports", "Travel", "Health & Fitness", "Food & Drink", "Finance",
        "Weather", "Reference", "Navigation", "Medical", "Books"
    ]
    
    // Minimum categories required (you can set this to all categories)
    private let minimumCategoriesRequired = 8 // Must select 11+ categories
    
    init() {
        loadSelectedApps()
        checkSetupCompliance()
    }
    
    func hasAllCategoriesSelected() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        return categoryCount >= minimumCategoriesRequired
    }
   
    @discardableResult
    func checkSetupCompliance() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        
        // Require all categories to be selected
        if categoryCount < minimumCategoriesRequired {
            setupError = "Please select at least \(minimumCategoriesRequired) app categories (\(categoryCount)/\(minimumCategoriesRequired) selected)"
            isSetupValid = false
            return false
        }
        
        setupError = nil
        isSetupValid = true
        return true
    }
    
    func getSetupValidationMessage() -> String {
        if isSetupValid {
            return "✓ Ready for Block-All Mode"
        } else {
            return setupError ?? "Setup incomplete"
        }
    }
    
    func getSelectedAppsDescription() -> String {
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
    
    func enable() {
        guard isSetupValid else {
            print("Cannot enable: Must select at least \(minimumCategoriesRequired) categories first")
            return
        }
        
        guard hasAllCategoriesSelected() else {
            print("Cannot enable: Not enough categories selected")
            return
        }
        
        print("Enabling Block-All Burner Mode...")
        print("Categories selected: \(selectedApps.categoryTokens.count)")
        print("Apps to keep available: \(selectedApps.applicationTokens.count)")
        
        // Request authorization
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                print("Authorization error: \(error)")
            }
        }
        
        // Block ALL categories except the selected apps (if any)
        if selectedApps.applicationTokens.isEmpty {
            // Block everything - no exceptions
            store.shield.applicationCategories = .all()
        } else {
            // Block all except selected apps
            store.shield.applicationCategories = .all(except: selectedApps.applicationTokens)
        }
        
        UserDefaults.standard.set(true, forKey: "burnerModeEnabled")
        print("Block-All Burner mode enabled")
    }
    
    func disable() {
        print("Disabling burner mode...")
        store.clearAllSettings()
        UserDefaults.standard.set(false, forKey: "burnerModeEnabled")
        print("Burner mode disabled")
    }
    
    func clearAllSelections() {
        selectedApps = FamilyActivitySelection()
        UserDefaults.standard.removeObject(forKey: "selectedApps")
    }
}
