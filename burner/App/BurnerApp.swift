import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct BurnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    @State private var shouldResetApp = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(appState.eventViewModel)
                    .environmentObject(appState.bookmarkManager)
                    .environmentObject(appState.ticketsViewModel)
                    .environmentObject(appState.authService)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
                    .onAppear {
                        appState.loadInitialData()
                        setupResetObserver()
                    }
                    .alert("Error", isPresented: $appState.showingError) {
                        Button("OK") {
                            appState.clearError()
                        }
                    } message: {
                        if let errorMessage = appState.errorMessage {
                            Text(errorMessage)
                        }
                    }
                    .id(shouldResetApp) // Forces view recreation when this changes
                
                // ✅ Global Burner Mode Lock Screen
                if appState.showingBurnerLockScreen {
                    BurnerModeLockScreen()
                        .environmentObject(appState)
                        .transition(.opacity)
                        .zIndex(1000) // Ensure it's on top of everything
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.showingBurnerLockScreen)
        }
    }
    
    private func setupResetObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ResetOnboarding"),
            object: nil,
            queue: .main
        ) { _ in
            // Toggle the state to force view recreation
            shouldResetApp.toggle()
        }
    }
}
