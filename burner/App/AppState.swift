import SwiftUI
import FirebaseAuth
import Combine

// MARK: - App State (Single Source of Truth)
@MainActor
class AppState: ObservableObject {
    // MARK: - Shared ViewModels
    @Published var eventViewModel: EventViewModel
    @Published var bookmarkManager: BookmarkManager
    @Published var ticketsViewModel: TicketsViewModel
    @Published var authService: AuthenticationService
    @Published var burnerModeMonitor: BurnerModeMonitor
    
    // MARK: - Global UI State
    @Published var isSignInSheetPresented = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    // ✅ Track if user manually signed out
    @Published var userDidSignOut = false
    
    // ✅ NEW: Global lock screen state
    @Published var showingBurnerLockScreen = false
    
    // Add flag to track initial auth check
    private var hasCompletedInitialAuthCheck = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Shared repository instances
    private let eventRepository: EventRepository
    private let ticketRepository: TicketRepository
    private let bookmarkRepository: BookmarkRepository
    private let userRepository: UserRepository
    private let purchaseService: PurchaseService
    
    // Burner Mode Manager (shared)
    let burnerManager: BurnerModeManager
    
    init() {
        // Initialize repositories (shared instances)
        self.eventRepository = EventRepository()
        self.ticketRepository = TicketRepository()
        self.bookmarkRepository = BookmarkRepository()
        self.userRepository = UserRepository()
        
        // Initialize services
        self.purchaseService = PurchaseService()
        
        // Initialize Burner Mode Manager
        self.burnerManager = BurnerModeManager()
        
        // Initialize ViewModels with shared repositories
        self.eventViewModel = EventViewModel(
            eventRepository: eventRepository,
            ticketRepository: ticketRepository,
            purchaseService: purchaseService
        )
        
        self.bookmarkManager = BookmarkManager(
            bookmarkRepository: bookmarkRepository,
            eventRepository: eventRepository
        )
        
        self.ticketsViewModel = TicketsViewModel(
            ticketRepository: ticketRepository
        )
        
        self.authService = AuthenticationService(
            userRepository: userRepository
        )
        
        // Initialize Burner Mode Monitor (will start monitoring immediately)
        self.burnerModeMonitor = BurnerModeMonitor(burnerManager: burnerManager)
        
        setupObservers()
        setupBurnerModeObserver()
    }
    
    // MARK: - Setup Observers
    private func setupObservers() {
        // Observe authentication state with initial check flag
        authService.$currentUser
            .sink { [weak self] user in
                guard let self = self else { return }
                
                // Skip showing sign-in sheet on initial load
                if !self.hasCompletedInitialAuthCheck {
                    self.hasCompletedInitialAuthCheck = true
                    
                    if user != nil {
                        self.handleUserSignedIn()
                    }
                    // Don't show sign-in sheet on first load - let user browse
                    return
                }
                
                // After initial check, handle sign-in/sign-out normally
                if user == nil {
                    // ✅ FIXED: Only show sign-in sheet if user didn't manually sign out
                    if !self.userDidSignOut {
                        self.isSignInSheetPresented = true
                    }
                    self.handleUserSignedOut()
                } else {
                    // ✅ Reset the sign-out flag when user signs back in
                    self.userDidSignOut = false
                    self.handleUserSignedIn()
                }
            }
            .store(in: &cancellables)
        
        // Observe EventViewModel errors
        eventViewModel.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
        
        // Observe TicketsViewModel errors
        ticketsViewModel.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Burner Mode Observer
    private func setupBurnerModeObserver() {
        // Listen for Burner Mode auto-enabled notification
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BurnerModeAutoEnabled"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                print("🔥 [AppState] Burner Mode auto-enabled notification received")
                self.showingBurnerLockScreen = true
            }
        }
        
        // Also check on app state initialization if burner mode is already enabled
        Task { @MainActor in
            let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
            if isEnabled {
                print("🔥 [AppState] Burner Mode already enabled on init, showing lock screen")
                self.showingBurnerLockScreen = true
            }
        }
    }
    
    // MARK: - User Sign In/Out Handlers
    private func handleUserSignedIn() {
        // Fetch data when user signs in
        eventViewModel.fetchEvents()
        ticketsViewModel.fetchUserTickets()
        
        // ✅ FIXED: Restart Burner Mode monitoring for new user
        burnerModeMonitor.stopMonitoring()
        burnerModeMonitor.startMonitoring()
        
        // Check if burner mode is enabled and show lock screen
        let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
        if isEnabled {
            print("🔥 [AppState] Burner Mode enabled on sign in, showing lock screen")
            showingBurnerLockScreen = true
        }
    }
    
    private func handleUserSignedOut() {
        // Clear all user-specific data
        bookmarkManager.clearBookmarks()
        ticketsViewModel.cleanup()
        eventViewModel.cleanup()
        
        // Stop Burner Mode monitoring
        burnerModeMonitor.stopMonitoring()
        
        // Hide lock screen if showing
        showingBurnerLockScreen = false
    }
    
    // ✅ Method to handle manual sign out
    func handleManualSignOut() {
        userDidSignOut = true
        isSignInSheetPresented = false
    }
    
    // MARK: - Global Error Handler
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    // MARK: - Initial Data Load
    func loadInitialData() {
        eventViewModel.fetchEvents()
        
        if authService.currentUser != nil {
            ticketsViewModel.fetchUserTickets()
        }
    }
}

// MARK: - Environment Key for AppState
struct AppStateKey: EnvironmentKey {
    @MainActor
    static let defaultValue = AppState()
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
