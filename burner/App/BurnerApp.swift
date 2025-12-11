import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Kingfisher
import ActivityKit
import UserNotifications

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Enable Firestore offline persistence
        let firestoreSettings = Firestore.firestore().settings
        firestoreSettings.cacheSettings = PersistentCacheSettings(
            sizeBytes: FirestoreCacheSizeUnlimited as NSNumber
        )
        firestoreSettings.isSSLEnabled = true
        Firestore.firestore().settings = firestoreSettings

        // Configure Kingfisher
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        cache.diskStorage.config.sizeLimit = 300 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)

        let downloader = ImageDownloader.default
        downloader.downloadTimeout = 15.0

        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        Task {
            await preloadEventsInBackground()
        }

        return true
    }
    
    private func preloadEventsInBackground() async {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        do {
            let snapshot = try await db.collection("events")
                .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: sevenDaysAgo))
                .getDocuments(source: .server)
            
            print("✅ Background preloaded \(snapshot.documents.count) events")
        } catch {
            print("⚠️ Background preload failed (non-critical): \(error.localizedDescription)")
        }
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) { return true }
        return false
    }
}

// MARK: - Global Appearance
private func configureGlobalAppearance() {
    let nav = UINavigationBarAppearance()
    nav.configureWithOpaqueBackground()
    nav.backgroundColor = .black
    nav.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont(name: "Avenir", size: 20)!]
    nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont(name: "Avenir", size: 32)!]
    UINavigationBar.appearance().standardAppearance = nav
    UINavigationBar.appearance().scrollEdgeAppearance = nav
    UINavigationBar.appearance().compactAppearance = nav
    UINavigationBar.appearance().tintColor = .white

    let tab = UITabBarAppearance()
    tab.configureWithOpaqueBackground()
    tab.backgroundColor = .black
    tab.stackedLayoutAppearance.selected.iconColor = .white
    UITabBar.appearance().standardAppearance = tab
    if #available(iOS 15.0, *) { UITabBar.appearance().scrollEdgeAppearance = tab }
    UITabBar.appearance().tintColor = .white
    UITabBar.appearance().unselectedItemTintColor = .lightGray
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
    
    init() { configureGlobalAppearance() }
    
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
                    .onOpenURL { url in handleIncomingURL(url) }
                    
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
                    VideoSplashView(videoName: "splash", loop: false) {
                        // Dismiss splash immediately when video ends
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.showingVideoSplash = false
                        }
                        // Continue loading in background
                        Task { await self.prefetchInBackground() }
                    }
                    .transition(.opacity)
                    .zIndex(2000)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.showingBurnerLockScreen)
            .animation(.easeInOut(duration: 0.4), value: showingVideoSplash)
            // ✅ MOVED HERE: Ensure initial load runs regardless of ZIndex layering
            .onAppear {
                appState.loadInitialData()
                setupResetObserver()
                setupNotificationObserver()
            }
            .id(shouldResetApp)
            .tint(.white)
            .foregroundColor(.white)
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            configureGlobalAppearance()
            if showingVideoSplash && (newPhase == .background || newPhase == .inactive) {
                showingVideoSplash = false
            }
            if newPhase == .active {
                UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
                if #available(iOS 16.1, *) {
                    TicketLiveActivityManager.updateLiveActivity()
                }
            }
        }
    }
    
    private func waitAndPrefetchThenDismissSplash() async {
        // Step 1: Wait for EventViewModel to signal load completion (success or failure)
        await appState.eventViewModel.waitForInitialLoad()

        // Step 2: Prefetch images
        await appState.prefetchEventImages()

        // Step 3: Dismiss splash
        await MainActor.run { showingVideoSplash = false }
    }

    private func prefetchInBackground() async {
        // Wait for EventViewModel to load
        await appState.eventViewModel.waitForInitialLoad()
        // Prefetch images in background
        await appState.prefetchEventImages()
    }
    
    // MARK: - URL Handling
    private func handleIncomingURL(_ url: URL) {
        if GIDSignIn.sharedInstance.handle(url) { return }
        if appState.passwordlessAuthHandler.handleSignInLink(url: url) { return }
        guard url.scheme?.lowercased() == "burner" else { return }
        
        if let deeplink = parseBurnerDeepLink(url) {
            switch deeplink {
            case .event(let id): navigateToEvent(eventId: id)
            case .ticket(let id): navigateToTicket(ticketId: id)
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
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        guard url.scheme?.lowercased() == "burner" else { return nil }
        
        if comps.host == "auth" {
            if let linkParam = comps.queryItems?.first(where: { $0.name == "link" })?.value,
               let authURL = URL(string: linkParam),
               let authScheme = authURL.scheme?.lowercased(),
               (authScheme == "https" || authScheme == "http"),
               let host = authURL.host,
               (host.hasSuffix("firebaseapp.com") || host.hasSuffix("burnerapp.com")) {
                return .auth(linkParam)
            }
            return nil
        }
        
        if comps.host == "event" {
            let id = url.lastPathComponent
            guard !id.isEmpty, isValidID(id) else { return nil }
            return .event(id)
        }
        
        if comps.host == "ticket" {
            let id = url.lastPathComponent
            guard !id.isEmpty, isValidID(id) else { return nil }
            return .ticket(id)
        }
        
        let parts = url.pathComponents.filter { $0 != "/" }
        if parts.count >= 2 {
            if parts[0] == "event" {
                let id = parts[1]
                guard !id.isEmpty, isValidID(id) else { return nil }
                return .event(id)
            } else if parts[0] == "ticket" {
                let id = parts[1]
                guard !id.isEmpty, isValidID(id) else { return nil }
                return .ticket(id)
            }
        }
        return nil
    }
    
    private func isValidID(_ id: String) -> Bool {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let idCharacterSet = CharacterSet(charactersIn: id)
        guard allowedCharacters.isSuperset(of: idCharacterSet), id.count >= 1, id.count <= 100 else { return false }
        return true
    }
    
    private func navigateToEvent(eventId: String) {
        appState.navigationCoordinator.handleDeepLink(eventId: eventId)
    }
    
    private func navigateToTicket(ticketId: String) {
        appState.navigationCoordinator.handleTicketDeepLink(ticketId: ticketId)
    }
    
    private func setupResetObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ResetOnboarding"), object: nil, queue: .main) { _ in
            shouldResetApp.toggle()
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UserTappedEventEndedNotification"), object: nil, queue: .main) { [weak appState] _ in
            guard let appState = appState else { return }
            Task { @MainActor in _ = appState.navigationCoordinator.explorePath }
        }
    }
}

extension AppState {
    func prefetchEventImages() async {
        guard !eventViewModel.events.isEmpty else { return }
        let events = eventViewModel.events
        let imagesToPrefetch = Array(events.prefix(15))
        await withTaskGroup(of: Void.self) { group in
            for event in imagesToPrefetch {
                group.addTask { await self.prefetchImage(url: event.imageUrl) }
            }
        }
    }
    
    private func prefetchImage(url: String) async {
        guard let imageURL = URL(string: url) else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ImagePrefetcher(urls: [imageURL]) { _, _, _ in continuation.resume() }.start()
        }
    }
}
