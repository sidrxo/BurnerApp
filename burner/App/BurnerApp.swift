import SwiftUI
import Supabase
import GoogleSignIn
import Kingfisher
import ActivityKit
import UserNotifications
import Shared

@main
struct BurnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appState = AppState()
    @StateObject var onboardingManager: OnboardingManager
    
    init() {
        // We create a temporary state to initialize the manager,
        // but the real one comes from @StateObject in body
        let tempState = AppState()
        _onboardingManager = StateObject(wrappedValue: tempState.onboardingManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(onboardingManager)
                // DELETED: .environmentObject(authService) -> It is not an ObservableObject!
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

// Keep your AppDelegate class exactly as it was
class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}
