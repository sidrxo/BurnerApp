import SwiftUI
import FirebaseCore
import GoogleSignIn

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return false
    }
}

// MARK: - Global Appearance
private func configureGlobalAppearance() {
    // Navigation Bar
    let nav = UINavigationBarAppearance()
    nav.configureWithOpaqueBackground()
    nav.backgroundColor = .black
    // 👇 Replace these with your preferred fonts
     nav.titleTextAttributes = [
         .foregroundColor: UIColor.white,
         .font: UIFont(name: "Avenir", size: 20)!
     ]
     nav.largeTitleTextAttributes = [
         .foregroundColor: UIColor.white,
         .font: UIFont(name: "Avenir", size: 32)!
     ]
    
    UINavigationBar.appearance().standardAppearance = nav
    UINavigationBar.appearance().scrollEdgeAppearance = nav
    UINavigationBar.appearance().compactAppearance = nav
    UINavigationBar.appearance().tintColor = .white

    // Tab Bar
    let tab = UITabBarAppearance()
    tab.configureWithOpaqueBackground()
    tab.backgroundColor = .black
    tab.stackedLayoutAppearance.selected.iconColor = .white
    tab.inlineLayoutAppearance.selected.iconColor = .white
    tab.compactInlineLayoutAppearance.selected.iconColor = .white
    tab.stackedLayoutAppearance.normal.iconColor = .lightGray
    tab.inlineLayoutAppearance.normal.iconColor = .lightGray
    tab.compactInlineLayoutAppearance.normal.iconColor = .lightGray
    UITabBar.appearance().standardAppearance = tab
    if #available(iOS 15.0, *) {
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
    UITabBar.appearance().tintColor = .white
    UITabBar.appearance().unselectedItemTintColor = .lightGray

    // UILabel (for all UIKit text)
    UILabel.appearance().textColor = .white
}

// MARK: - App
@main
struct BurnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    @State private var shouldResetApp = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(appState.eventViewModel)
                    .environmentObject(appState.bookmarkManager)
                    .environmentObject(appState.ticketsViewModel)
                    .environmentObject(appState.authService)
                    .environmentObject($appState.tabBarVisibility) // 👈 add this
                    .onOpenURL { url in
                        handleIncomingURL(url)
                    }
                    .onAppear {
                        appState.loadInitialData()
                        setupResetObserver()
                    }
                    .alert("Error", isPresented: $appState.showingError) {
                        Button("OK") { appState.clearError() }
                    } message: {
                        if let errorMessage = appState.errorMessage {
                            Text(errorMessage)
                        }
                    }
                    .id(shouldResetApp)
                    // 🔥 Force all SwiftUI text to white globally
                    .tint(.white)
                    .foregroundColor(.white)
                    .preferredColorScheme(.dark)
                
                if appState.showingBurnerLockScreen {
                    BurnerModeLockScreen()
                        .environmentObject(appState)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.showingBurnerLockScreen)
        }
        .onChange(of: scenePhase) { _ in
            configureGlobalAppearance()
        }
    }

    // MARK: - URL Handling
    private func handleIncomingURL(_ url: URL) {
        print("🔗 Received URL: \(url.absoluteString)")

        // 1) Google Sign-In first
        if GIDSignIn.sharedInstance.handle(url) {
            print("✅ Handled by Google Sign-In")
            return
        }

        // 2) Our custom scheme(s)
        guard url.scheme?.lowercased() == "burner" else { return }

        if let deeplink = parseBurnerDeepLink(url) {
            switch deeplink {
            case .event(let id):
                print("✅ Deep link → event id: \(id)")
                navigateToEvent(eventId: id)
            }
        } else {
            print("❌ Invalid deep link format")
        }
    }

    private enum BurnerDeepLink {
        case event(String)
    }

    private func parseBurnerDeepLink(_ url: URL) -> BurnerDeepLink? {
        // Prefer URLComponents for robustness
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        // Case A: scheme://event/{id}  (host-based)
        if comps.host == "event" {
            let id = url.lastPathComponent
            return id.isEmpty ? nil : .event(id)
        }

        // Case B: scheme:///event/{id} (path-based)
        let parts = url.pathComponents.filter { $0 != "/" }
        if parts.count >= 2, parts[0] == "event" {
            let id = parts[1]
            return id.isEmpty ? nil : .event(id)
        }

        return nil
    }

    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Handling Burner deep link: \(url.absoluteString)")
        
        // Parse the URL path
        // Format: burner://event/{eventId}
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard pathComponents.count >= 2,
              pathComponents[0] == "event" else {
            print("❌ Invalid deep link format")
            return
        }
        
        let eventId = pathComponents[1]
        print("✅ Opening event with ID: \(eventId)")
        
        // Navigate to the event
        navigateToEvent(eventId: eventId)
    }
    
 private func navigateToEvent(eventId: String) {
        appState.selectedTab = 1         // switch to Events tab
        appState.navigationPath = NavigationPath() // optional: reset stack
        appState.navigationPath.append(eventId)    // push detail
    }


    private func setupResetObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ResetOnboarding"),
            object: nil,
            queue: .main
        ) { _ in
            shouldResetApp.toggle()
        }
    }
}
