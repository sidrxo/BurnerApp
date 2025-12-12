import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Kingfisher
import ActivityKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        let firestoreSettings = Firestore.firestore().settings
        firestoreSettings.cacheSettings = PersistentCacheSettings(
            sizeBytes: FirestoreCacheSizeUnlimited as NSNumber
        )
        Firestore.firestore().settings = firestoreSettings

        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        cache.diskStorage.config.sizeLimit = 300 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)

        let downloader = ImageDownloader.default
        downloader.downloadTimeout = 15.0

        UNUserNotificationCenter.current().delegate = notificationDelegate

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

private func configureGlobalAppearance() {
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

    UILabel.appearance().textColor = .white
}

@main
struct BurnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    @State private var shouldResetApp = false
    @State private var showingVideoSplash = true
    @Environment(\.scenePhase) private var scenePhase
    
    // Check if this is the very first launch.
    private let isInitialAppLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    
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
                        setupNotificationObserver()
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
                
                if showingVideoSplash {
                    // MARK: - Updated logic for video selection
                    let videoToPlay = isInitialAppLaunch ? "launch" : "splash"
                    VideoSplashView(videoName: videoToPlay, loop: false) {
                        showingVideoSplash = false
                    }
                    .zIndex(2000)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.showingBurnerLockScreen)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            configureGlobalAppearance()
            
            // MARK: - Updated logic to only dismiss splash on background if it's NOT the initial launch (to ensure 'launch' video plays fully)
            if !isInitialAppLaunch && showingVideoSplash && (newPhase == .background || newPhase == .inactive) {
                showingVideoSplash = false
            }
            
            if newPhase == .active {
                UNUserNotificationCenter.current().setBadgeCount(0) { error in
                    if let error = error {
                        print("⚠️ Error clearing badge count: \(error.localizedDescription)")
                    }
                }
                
                if #available(iOS 16.1, *) {
                    TicketLiveActivityManager.updateLiveActivity()
                }
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        if GIDSignIn.sharedInstance.handle(url) {
            return
        }
        
        if appState.passwordlessAuthHandler.handleSignInLink(url: url) {
            return
        }
        
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
        
        guard url.scheme?.lowercased() == "burner" else {
            return nil
        }
        
        if comps.host == "auth" {
            if let linkParam = comps.queryItems?.first(where: { $0.name == "link" })?.value {
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
        
        if comps.host == "event" {
            let id = url.lastPathComponent
            guard !id.isEmpty, isValidID(id) else {
                return nil
            }
            return .event(id)
        }
        
        if comps.host == "ticket" {
            let id = url.lastPathComponent
            guard !id.isEmpty, isValidID(id) else {
                return nil
            }
            return .ticket(id)
        }
        
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
    
    private func isValidID(_ id: String) -> Bool {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let idCharacterSet = CharacterSet(charactersIn: id)
        guard allowedCharacters.isSuperset(of: idCharacterSet),
              id.count >= 1,
              id.count <= 100 else {
            return false
        }
        return true
    }
    
    private func navigateToEvent(eventId: String) {
        appState.navigationCoordinator.handleDeepLink(eventId: eventId)
    }
    
    private func navigateToTicket(ticketId: String) {
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
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserTappedEventEndedNotification"),
            object: nil,
            queue: .main
        ) { [weak appState] _ in
            guard let appState = appState else { return }

            Task { @MainActor in
                _ = appState.navigationCoordinator.explorePath
            }
        }
    }
}
