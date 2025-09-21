import Foundation
import FamilyControls
import Combine

@MainActor
class BurnerModeManager: ObservableObject {
    @Published var isEnabled = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var blockedAppsSelection = FamilyActivitySelection()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.gas.Burner")
    
    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        loadBurnerModeState()
        loadBlockedAppsSelection()
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            print("Failed to request authorization: \(error)")
        }
    }
    
    func enableBurnerMode() async {
        // Check if we're already authorized
        if authorizationStatus != .approved {
            // If not, request authorization
            await requestAuthorization()
            
            // Check again after requesting
            if authorizationStatus != .approved {
                // Still not authorized, so we can't enable burner mode
                return
            }
        }
        
        // If we reach here, authorization is approved
        isEnabled = true
        saveBurnerModeState()
        
        // Show a notification that burner mode is active
        showBurnerModeNotification()
    }
    
    func disableBurnerMode() async {
        isEnabled = false
        saveBurnerModeState()
    }
    
    func updateBlockedApps(_ selection: FamilyActivitySelection) {
        blockedAppsSelection = selection
        saveBlockedAppsSelection()
    }
    
    private func showBurnerModeNotification() {
        // For now, just print - you could show an alert or notification
        print("🔥 Burner Mode Active - App blocking will be enabled once additional permissions are granted")
    }
    
    private func saveBurnerModeState() {
        sharedDefaults?.set(isEnabled, forKey: "burnerModeEnabled")
    }
    
    private func loadBurnerModeState() {
        isEnabled = sharedDefaults?.bool(forKey: "burnerModeEnabled") ?? false
    }
    
    private func saveBlockedAppsSelection() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(blockedAppsSelection) {
            sharedDefaults?.set(data, forKey: "blockedAppsSelection")
        }
    }
    
    private func loadBlockedAppsSelection() {
        if let data = sharedDefaults?.data(forKey: "blockedAppsSelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            blockedAppsSelection = selection
        }
    }
    
    // Helper property to check if apps are selected
    var hasSelectedApps: Bool {
        !blockedAppsSelection.applicationTokens.isEmpty || !blockedAppsSelection.categoryTokens.isEmpty
    }
}
