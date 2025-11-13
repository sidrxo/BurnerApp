import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Kingfisher
import ActivityKit

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Enable Firestore offline persistence for better caching and reduced reads
        let firestoreSettings = Firestore.firestore().settings
        firestoreSettings.cacheSettings = PersistentCacheSettings(
            sizeBytes: FirestoreCacheSizeUnlimited as NSNumber
        )
        Firestore.firestore().settings = firestoreSettings

        // Configure Kingfisher for optimized image loading
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB memory cache
        cache.diskStorage.config.sizeLimit = 300 * 1024 * 1024 // 300 MB disk cache
        cache.diskStorage.config.expiration = .days(7) // 7 days expiration

        // Configure downloader
        let downloader = ImageDownloader.default
        downloader.downloadTimeout = 15.0 // 15 seconds timeout

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
    @State private var showingVideoSplash = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureGlobalAppearance()

    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(appState.navigationCoordinator)
                    .environmentObject(appState.eventViewModel)
                    .environmentObject(appState.bookmarkManager)
                    .environmentObject(appState.ticketsViewModel)
                    .environmentObject(appState.tagViewModel)
                    .environmentObject(appState.authService)
                    .environmentObject(appState.userLocationManager)
                    .onOpenURL { url in
                        handleIncomingURL(url)
                    }
                    .onAppear {
                        appState.loadInitialData()
                        setupResetObserver()
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

                if appState.showingError {
                    CustomAlertView(
                        title: "Error",
                        description: appState.errorMessage ?? "An error occurred",
                        primaryAction: { appState.clearError() },
                        primaryActionTitle: "OK",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1001)
                }
                
                // Video splash - separate from error block
                if showingVideoSplash {
                    VideoSplashView(videoName: "splash", loop: false) {
                        
                            showingVideoSplash = false
                        
                    }
                    .zIndex(2000)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.showingBurnerLockScreen)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            configureGlobalAppearance()

            // Update live activities when app becomes active
            if newPhase == .active {
                if #available(iOS 16.1, *) {
                    TicketLiveActivityManager.updateLiveActivity()
                }
            }
        }
    }

    // MARK: - URL Handling
    private func handleIncomingURL(_ url: URL) {
        // 1) Google Sign-In first
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }

        // 2) Check for Firebase passwordless sign-in link
        if appState.passwordlessAuthHandler.handleSignInLink(url: url) {
            return
        }

        // 3) Our custom scheme(s)
        guard url.scheme?.lowercased() == "burner" else {
            return
        }

        if let deeplink = parseBurnerDeepLink(url) {
            switch deeplink {
            case .event(let id):
                navigateToEvent(eventId: id)
            case .auth(let link):
                // Handle the passwordless auth link
                if let linkUrl = URL(string: link) {
                    _ = appState.passwordlessAuthHandler.handleSignInLink(url: linkUrl)
                }
            }
        }
    }

    private enum BurnerDeepLink {
        case event(String)
        case auth(String)
    }

    private func parseBurnerDeepLink(_ url: URL) -> BurnerDeepLink? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // Case A: burner://auth?link=<url> (passwordless auth)
        if comps.host == "auth" {
            if let linkParam = comps.queryItems?.first(where: { $0.name == "link" })?.value {
                return .auth(linkParam)
            }
            return nil
        }

        // Case B: burner://event/12345 (host-based)
        if comps.host == "event" {
            let id = url.lastPathComponent
            return id.isEmpty ? nil : .event(id)
        }

        // Case C: burner:///event/12345 (path-based)
        let parts = url.pathComponents.filter { $0 != "/" }

        if parts.count >= 2, parts[0] == "event" {
            let id = parts[1]
            return id.isEmpty ? nil : .event(id)
        }

        return nil
    }
    
    private func navigateToEvent(eventId: String) {
        // Use NavigationCoordinator for deep linking
        appState.navigationCoordinator.handleDeepLink(eventId: eventId)
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
