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

    private var tabBarVisibility: TabBarVisibility {
        TabBarVisibility(isDetailViewPresented: Binding(
            get: { appState.isDetailViewPresented },
            set: { appState.isDetailViewPresented = $0 }
        ))
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
                    .environmentObject(tabBarVisibility)
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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            configureGlobalAppearance()
        }
    }

    // MARK: - URL Handling
    private func handleIncomingURL(_ url: URL) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔗 INCOMING URL")
        print("   Full URL: \(url.absoluteString)")
        print("   Scheme: \(url.scheme ?? "nil")")
        print("   Host: \(url.host ?? "nil")")
        print("   Path: \(url.path)")
        print("   Path Components: \(url.pathComponents)")
        print("   Last Component: \(url.lastPathComponent)")

        // 1) Google Sign-In first
        if GIDSignIn.sharedInstance.handle(url) {
            print("✅ Handled by Google Sign-In")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        // 2) Our custom scheme(s)
        guard url.scheme?.lowercased() == "burner" else {
            print("⚠️ Not a burner:// URL, ignoring")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        if let deeplink = parseBurnerDeepLink(url) {
            switch deeplink {
            case .event(let id):
                print("✅ Parsed as event deep link")
                print("   Event ID: \(id)")
                print("   ID length: \(id.count)")
                navigateToEvent(eventId: id)
            }
        } else {
            print("❌ Failed to parse deep link")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }

    private enum BurnerDeepLink {
        case event(String)
    }

    private func parseBurnerDeepLink(_ url: URL) -> BurnerDeepLink? {
        print("🔍 Parsing deep link...")
        
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Failed to create URLComponents")
            return nil
        }

        // Case A: burner://event/12345 (host-based)
        if comps.host == "event" {
            print("   Detected host-based format: burner://event/ID")
            let id = url.lastPathComponent
            print("   Extracted ID: '\(id)'")
            return id.isEmpty ? nil : .event(id)
        }

        // Case B: burner:///event/12345 (path-based)
        let parts = url.pathComponents.filter { $0 != "/" }
        print("   Path components (filtered): \(parts)")
        
        if parts.count >= 2, parts[0] == "event" {
            print("   Detected path-based format: burner:///event/ID")
            let id = parts[1]
            print("   Extracted ID: '\(id)'")
            return id.isEmpty ? nil : .event(id)
        }

        print("   No valid format detected")
        return nil
    }
    
    private func navigateToEvent(eventId: String) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🚀 DEEP LINK NAVIGATION")
        print("   Event ID: \(eventId)")
        print("   Current tab: \(appState.selectedTab)")
        
        // Switch to Home tab
        appState.selectedTab = 0
        print("✅ Switched to Home tab")
        
        // Small delay to ensure tab has switched
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Post notification for HomeView to handle
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToEvent"),
                object: eventId
            )
            print("📢 Posted NavigateToEvent notification with ID: \(eventId)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
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
