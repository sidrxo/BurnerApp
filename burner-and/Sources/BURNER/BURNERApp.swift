import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

@main
struct BurnerApp: App {
    // Skip handles the Android Lifecycle mapping automatically for simple Apps
    @StateObject private var appState = AppState()
    
    init() {
        // Shared Initialization Logic
        configureAppearance()
        
        // On Android, Firebase is auto-configured by the google-services.json
        // On iOS, we need to initialize it manually if not done implicitly
        #if !os(Android)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(appState.onboardingManager)
                .environmentObject(appState.navigationCoordinator)
                .environmentObject(appState.eventViewModel)
                .environmentObject(appState.bookmarkManager)
                .environmentObject(appState.ticketsViewModel)
                .environmentObject(appState.tagViewModel)
                .environmentObject(appState.authService)
                .environmentObject(appState.userLocationManager)
        }
    }
    
    func configureAppearance() {
        // Simple appearance configuration
        // Advanced UIKit appearance proxies (UINavigationBar.appearance)
        // are ignored on Android, so we keep this minimal or wrapped in #if !os(Android)
    }
}
