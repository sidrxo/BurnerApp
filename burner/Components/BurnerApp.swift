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
    
    var body: some Scene {
        WindowGroup {
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
        }
    }
}
