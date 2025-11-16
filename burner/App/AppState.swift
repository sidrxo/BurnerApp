import SwiftUI
import FirebaseAuth
import Combine
import ActivityKit

// MARK: - App State (Single Source of Truth)
@MainActor
class AppState: ObservableObject {
    // MARK: - Shared ViewModels
    @Published var eventViewModel: EventViewModel
    @Published var bookmarkManager: BookmarkManager
    @Published var ticketsViewModel: TicketsViewModel
    @Published var tagViewModel: TagViewModel
    @Published var authService: AuthenticationService
    @Published var passwordlessAuthHandler: PasswordlessAuthHandler
    @Published var userLocationManager: UserLocationManager

    // MARK: - Navigation Coordinator
    @Published var navigationCoordinator: NavigationCoordinator

    // MARK: - Global UI State
    @Published var isSignInSheetPresented = false
    @Published var showingError = false
    @Published var errorMessage: String?

    // ✅ Track if user manually signed out
    @Published var userDidSignOut = false

    // Debug
    @Published var isSimulatingEmptyFirestore = false

    // ✅ User role and scanner status (fetched on sign in)
    @Published var userRole: String = ""
    @Published var isScannerActive: Bool = false
    
    // ✅ NEW: Global lock screen state
    @Published var showingBurnerLockScreen = false
    
    // Add flag to track initial auth check
    private var hasCompletedInitialAuthCheck = false
    
    private var cancellables = Set<AnyCancellable>()

    // NotificationCenter observers (need cleanup)
    private var burnerModeObserver: NSObjectProtocol?
    private var resetObserver: NSObjectProtocol?
    private var emptyStateEnabledObserver: NSObjectProtocol?
    private var emptyStateDisabledObserver: NSObjectProtocol?

    // Shared repository instances
    private let eventRepository: EventRepository
    private let ticketRepository: TicketRepository
    private let bookmarkRepository: BookmarkRepository
    private let userRepository: UserRepository

    // Burner Mode Manager (shared)
    let burnerManager: BurnerModeManager
    
    // ✅ FIXED: Use lazy initialization for burnerModeMonitor to avoid using 'self' before initialization
    lazy var burnerModeMonitor: BurnerModeMonitor = {
        BurnerModeMonitor(appState: self, burnerManager: self.burnerManager)
    }()

    deinit {
        // Remove all NotificationCenter observers
        if let observer = burnerModeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = resetObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = emptyStateEnabledObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = emptyStateDisabledObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Cancel all Combine subscriptions
        cancellables.removeAll()
    }
    
    init() {
        // Initialize repositories (shared instances)
        self.eventRepository = EventRepository()
        self.ticketRepository = TicketRepository()
        self.bookmarkRepository = BookmarkRepository()
        self.userRepository = UserRepository()
        
        // Initialize services
        self.userLocationManager = UserLocationManager()
        
        // Initialize Burner Mode Manager
        self.burnerManager = BurnerModeManager()
        
        // Initialize ViewModels with shared repositories
        self.eventViewModel = EventViewModel(
            eventRepository: eventRepository,
            ticketRepository: ticketRepository,
        )
        
        self.bookmarkManager = BookmarkManager(
            bookmarkRepository: bookmarkRepository,
            eventRepository: eventRepository
        )
        
        self.ticketsViewModel = TicketsViewModel(
            ticketRepository: ticketRepository
        )

        self.tagViewModel = TagViewModel()

        self.authService = AuthenticationService(
            userRepository: userRepository
        )

        // Initialize Passwordless Auth Handler
        self.passwordlessAuthHandler = PasswordlessAuthHandler()

        // Initialize Navigation Coordinator
        self.navigationCoordinator = NavigationCoordinator()

        // ✅ FIXED: Trigger lazy initialization of burnerModeMonitor after all properties are initialized
        _ = burnerModeMonitor

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
        // Listen for Burner Mode auto-enabled notification and store observer
        burnerModeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BurnerModeAutoEnabled"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.showingBurnerLockScreen = true
            }
        }
        
        // Also check on app state initialization if burner mode is already enabled
        Task { @MainActor in
            let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
            if isEnabled {
                self.showingBurnerLockScreen = true
            }
        }
    }
    
    // MARK: - User Sign In/Out Handlers
    private func handleUserSignedIn() {
        // Fetch data when user signs in
        if !isSimulatingEmptyFirestore {
            eventViewModel.fetchEvents()
            ticketsViewModel.fetchUserTickets()
            bookmarkManager.refreshBookmarks()
        }

        // ✅ FIXED: Restart Burner Mode monitoring for new user
        burnerModeMonitor.stopMonitoring()
        burnerModeMonitor.startMonitoring()

        // Check if burner mode is enabled and show lock screen
        let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
        if isEnabled {
            showingBurnerLockScreen = true
        }

        // ✅ Fetch and store user role and scanner status
        Task {
            do {
                userRole = try await authService.getUserRole() ?? ""
                isScannerActive = try await authService.isScannerActive()
            } catch {
                userRole = ""
                isScannerActive = false
            }
        }
    }
    
    private func handleUserSignedOut() {
        // Clear all user-specific data immediately to prevent errors
        ticketsViewModel.clearTickets()
        bookmarkManager.clearBookmarks()

        // Then cleanup listeners
        ticketsViewModel.cleanup()
        eventViewModel.cleanup()

        // Stop Burner Mode monitoring
        burnerModeMonitor.stopMonitoring()

        // Hide lock screen if showing
        showingBurnerLockScreen = false

        // ✅ Clear user role and scanner status
        userRole = ""
        isScannerActive = false
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
        if isSimulatingEmptyFirestore {
            eventViewModel.simulateEmptyData()
            ticketsViewModel.simulateEmptyData()
            bookmarkManager.simulateEmptyData()
        } else {
            eventViewModel.fetchEvents()

            if authService.currentUser != nil {
                ticketsViewModel.fetchUserTickets()
            }
        }
    }

    // MARK: - Debug Helpers
    func enableEmptyFirestoreSimulation() {
        guard !isSimulatingEmptyFirestore else { return }
        isSimulatingEmptyFirestore = true
        eventViewModel.simulateEmptyData()
        ticketsViewModel.simulateEmptyData()
        bookmarkManager.simulateEmptyData()

        // Notify SearchView to clear its results
        NotificationCenter.default.post(name: NSNotification.Name("EmptyStateEnabled"), object: nil)

        // Set up observer for empty state (if not already set)
        if emptyStateEnabledObserver == nil {
            emptyStateEnabledObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("EmptyStateEnabled"),
                object: nil,
                queue: .main
            ) { _ in
                // Handle empty state enabled if needed
            }
        }
    }

    func disableEmptyFirestoreSimulation() {
        guard isSimulatingEmptyFirestore else { return }
        isSimulatingEmptyFirestore = false
        eventViewModel.resumeFromSimulation()
        ticketsViewModel.resumeFromSimulation()
        bookmarkManager.resumeFromSimulation()

        // Notify SearchView to restore its results
        NotificationCenter.default.post(name: NSNotification.Name("EmptyStateDisabled"), object: nil)

        // Set up observer for empty state (if not already set)
        if emptyStateDisabledObserver == nil {
            emptyStateDisabledObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("EmptyStateDisabled"),
                object: nil,
                queue: .main
            ) { _ in
                // Handle empty state disabled if needed
            }
        }
    }
    
    // MARK: - Live Activity Debug Methods
    
    // Simulate event that hasn't started yet (no progress bar)
    func simulateEventBeforeStart() {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .hour, value: 2, to: now)!
        let endTime = calendar.date(byAdding: .hour, value: 6, to: now)!
        
        createDebugEvent(startTime: startTime, endTime: endTime)
    }
    
    // Simulate event that's already started (with progress bar)
    func simulateEventDuringEvent() {
        let calendar = Calendar.current
        let now = Date()
        // Event started 1 hour ago
        let startTime = calendar.date(byAdding: .hour, value: -1, to: now)!
        // Event ends in 3 hours
        let endTime = calendar.date(byAdding: .hour, value: 3, to: now)!

        createDebugEvent(startTime: startTime, endTime: endTime)
    }

    // Create a purchasable debug event starting soon
    func addDebugPurchasableEvent() {
        let now = Date()
        let startTime = now.addingTimeInterval(5 * 60)
        let endTime = now.addingTimeInterval(10 * 60)

        let debugEvent = Event(
            id: "debug_purchasable_event_\(UUID().uuidString)",
            name: "Debug Express Entry",
            venue: "Burner Labs",
            venueId: nil,
            startTime: startTime,
            endTime: endTime,
            price: 12.5,
            maxTickets: 200,
            ticketsSold: 0,
            imageUrl: "https://images.unsplash.com/photo-1506157786151-b8491531f063",
            isFeatured: false,
            description: "A temporary debug event that starts in 5 minutes for testing ticket purchases.",
            status: "active",
            tags: ["debug", "test"],
            coordinates: nil,
            createdAt: now,
            updatedAt: now
        )

        eventViewModel.addDebugEvent(debugEvent)
    }
    
    private func createDebugEvent(startTime: Date, endTime: Date) {
        let now = Date()
        
        // Create a test ticket with all required fields
        let testTicket = Ticket(
            id: "debug_ticket_\(UUID().uuidString)",
            eventId: "debug_event_\(UUID().uuidString)",
            userId: authService.currentUser?.uid ?? "debug_user",
            ticketNumber: "DEBUG-\(Int.random(in: 1000...9999))",
            eventName: "Garage Classics",
            venue: "Ministry of Sound",
            startTime: startTime,
            totalPrice: 0.00,
            purchaseDate: now,
            status: "confirmed",
            qrCode: "DEBUG_QR_\(UUID().uuidString)",
            venueId: nil,
            usedAt: nil,
            scannedBy: nil,
            cancelledAt: nil,
            cancelReason: nil,
            refundedAt: nil,
            refundAmount: nil,
            transferredFrom: nil,
            transferredAt: nil,
            updatedAt: now
        )
        
        // Add to tickets view model
        ticketsViewModel.addDebugTicket(testTicket)
        
        // Start live activity
        if #available(iOS 16.1, *) {
            // Create attributes for Live Activity
            let attributes = TicketActivityAttributes(
                eventName: testTicket.eventName,
                venue: testTicket.venue,
                startTime: testTicket.startTime,
                endTime: endTime,
                ticketId: testTicket.id ?? "test-ticket-id"
            )
            
            // Calculate initial content state (no need for progress - ProgressView handles it)
            let now = Date()
            let hasStarted = now >= testTicket.startTime
            let hasEnded = now >= endTime
            let contentState = TicketActivityAttributes.ContentState(
                eventStartTime: testTicket.startTime,
                eventEndTime: endTime,
                hasEventStarted: hasStarted,
                hasEventEnded: hasEnded
            )
            
            // Start the Live Activity
            do {
                if #available(iOS 16.2, *) {
                    _ = try Activity<TicketActivityAttributes>.request(
                        attributes: attributes,
                        content: .init(state: contentState, staleDate: nil),
                        pushType: nil
                    )
                } else {
                    _ = try Activity<TicketActivityAttributes>.request(
                        attributes: attributes,
                        contentState: contentState,
                        pushType: nil
                    )
                }
            } catch {
                // Live activity start failed silently
            }
        }
    }
    
    func clearDebugEventToday() {
        // Remove debug tickets from view model
        ticketsViewModel.removeDebugTickets()
        
        // End all live activities
        if #available(iOS 16.1, *) {
            TicketLiveActivityManager.endLiveActivity()
        }
    }
}
