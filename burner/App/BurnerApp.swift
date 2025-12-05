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
        // Configure Firebase
        FirebaseApp.configure()

        // Enable Firestore offline persistence for better caching and reduced reads
        // This also helps prevent early network connection warnings
        let firestoreSettings = Firestore.firestore().settings
        firestoreSettings.cacheSettings = PersistentCacheSettings(
            sizeBytes: FirestoreCacheSizeUnlimited as NSNumber
        )
        firestoreSettings.isSSLEnabled = true
        Firestore.firestore().settings = firestoreSettings

        // Disable automatic network connectivity checks to prevent early connection warnings
        // Network will still be used when needed, but won't attempt immediate connection
        Firestore.firestore().disableNetwork { error in
            if let error = error {
                print("⚠️ Error disabling network: \(error.localizedDescription)")
            }
            // Re-enable network after a brief delay to allow app to fully initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Firestore.firestore().enableNetwork { error in
                    if let error = error {
                        print("⚠️ Error enabling network: \(error.localizedDescription)")
                    }
                }
            }
        }

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
                    .environmentObject(appState.onboardingManager)
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

            // Dismiss splash screen if app is backgrounded or becomes inactive during splash
            if showingVideoSplash && (newPhase == .background || newPhase == .inactive) {
                showingVideoSplash = false
            }

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
            case .ticket(let id):
                navigateToTicket(ticketId: id)
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
        case ticket(String)
        case auth(String)
    }

    private func parseBurnerDeepLink(_ url: URL) -> BurnerDeepLink? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        // ✅ SECURITY: Validate URL scheme strictly
        guard url.scheme?.lowercased() == "burner" else {
            return nil
        }

        // Case A: burner://auth?link=<url> (passwordless auth)
        if comps.host == "auth" {
            if let linkParam = comps.queryItems?.first(where: { $0.name == "link" })?.value {
                // ✅ SECURITY: Validate auth link URL
                guard let authURL = URL(string: linkParam),
                      let authScheme = authURL.scheme?.lowercased(),
                      (authScheme == "https" || authScheme == "http"),
                      let host = authURL.host,
                      (host.hasSuffix("firebaseapp.com") || host.hasSuffix("burnerapp.com")) else {
                    return nil
                }
                return .auth(linkParam)
            }
            return nil
        }

        // Case B: burner://event/12345 (host-based)
        if comps.host == "event" {
            let id = url.lastPathComponent
            // ✅ SECURITY: Validate ID format (alphanumeric + hyphens/underscores only)
            guard !id.isEmpty, isValidID(id) else {
                return nil
            }
            return .event(id)
        }

        // Case B2: burner://ticket/12345 (host-based)
        if comps.host == "ticket" {
            let id = url.lastPathComponent
            // ✅ SECURITY: Validate ID format
            guard !id.isEmpty, isValidID(id) else {
                return nil
            }
            return .ticket(id)
        }

        // Case C: burner:///event/12345 or burner:///ticket/12345 (path-based)
        let parts = url.pathComponents.filter { $0 != "/" }

        if parts.count >= 2 {
            if parts[0] == "event" {
                let id = parts[1]
                guard !id.isEmpty, isValidID(id) else {
                    return nil
                }
                return .event(id)
            } else if parts[0] == "ticket" {
                let id = parts[1]
                guard !id.isEmpty, isValidID(id) else {
                    return nil
                }
                return .ticket(id)
            }
        }

        return nil
    }

    // ✅ SECURITY: Validate ID format to prevent injection
    private func isValidID(_ id: String) -> Bool {
        // Allow alphanumeric characters, hyphens, and underscores only
        // Typical Firestore IDs are 20-28 characters
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let idCharacterSet = CharacterSet(charactersIn: id)
        guard allowedCharacters.isSuperset(of: idCharacterSet),
              id.count >= 1,
              id.count <= 100 else { // Reasonable length limit
            return false
        }
        return true
    }
    
    private func navigateToEvent(eventId: String) {
        // Use NavigationCoordinator for deep linking
        appState.navigationCoordinator.handleDeepLink(eventId: eventId)
    }

    private func navigateToTicket(ticketId: String) {
        // Use NavigationCoordinator for ticket deep linking
        appState.navigationCoordinator.handleTicketDeepLink(ticketId: ticketId)
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
