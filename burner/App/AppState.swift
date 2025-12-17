import SwiftUI
import Supabase
import Combine
import ActivityKit
import Kingfisher
import FamilyControls

@MainActor
class AppState: ObservableObject {
    @Published var eventViewModel: EventViewModel
    @Published var bookmarkManager: BookmarkManager
    @Published var ticketsViewModel: TicketsViewModel
    @Published var tagViewModel: TagViewModel
    @Published var authService: AuthenticationService
    @Published var passwordlessAuthHandler: PasswordlessAuthHandler
    @Published var userLocationManager: UserLocationManager
    @Published var onboardingManager: OnboardingManager
    @Published var navigationCoordinator: NavigationCoordinator
    @Published var isSignInSheetPresented = false
    @Published var showingError = false
    @Published var errorMessage: String?
    @Published var userDidSignOut = false
    @Published var userRole: String = ""
    @Published var userDisplayName: String = ""
    @Published var isScannerActive: Bool = false
    @Published var showingBurnerLockScreen = false
    @Published var burnerSetupCompleted: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var burnerModeObserver: NSObjectProtocol?
    private var resetObserver: NSObjectProtocol?
    private var imagePrefetchCancellable: AnyCancellable?

    private let eventRepository: EventRepository
    private let ticketRepository: TicketRepository
    private let bookmarkRepository: BookmarkRepository
    private let userRepository: UserRepository

    let burnerManager: BurnerModeManager

    lazy var burnerModeMonitor: BurnerModeMonitor = {
        BurnerModeMonitor(appState: self, burnerManager: self.burnerManager)
    }()
    
    lazy var stripePaymentService: StripePaymentService = {
        StripePaymentService(appState: self)
    }()

    deinit {
        if let observer = burnerModeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = resetObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        cancellables.removeAll()
    }

    init() {
        self.eventRepository = EventRepository()
        self.ticketRepository = TicketRepository()
        self.bookmarkRepository = BookmarkRepository()
        self.userRepository = UserRepository()

        self.userLocationManager = UserLocationManager()
        self.burnerManager = BurnerModeManager()
        self.onboardingManager = OnboardingManager()

        self.eventViewModel = EventViewModel(
            eventRepository: eventRepository,
            ticketRepository: ticketRepository
        )

        self.ticketsViewModel = TicketsViewModel(
            ticketRepository: ticketRepository
        )

        self.bookmarkManager = BookmarkManager(
            bookmarkRepository: bookmarkRepository,
            eventRepository: eventRepository
        )

        self.tagViewModel = TagViewModel()

        self.authService = AuthenticationService(
            userRepository: userRepository
        )

        self.passwordlessAuthHandler = PasswordlessAuthHandler()
        self.navigationCoordinator = NavigationCoordinator()

        self.onboardingManager = OnboardingManager(authService: self.authService)

        self.burnerManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        _ = burnerModeMonitor

        setupObservers()
        setupBurnerModeObserver()
        setupImagePrefetching()
        loadBurnerSetupState()

        loadInitialData()
        self.eventViewModel.setTicketsViewModel(ticketsViewModel)
    }

    private func loadBurnerSetupState() {
        burnerSetupCompleted = UserDefaults.standard.bool(forKey: "burnerSetupCompleted")
    }

    private func setupObservers() {
        authService.$currentUser
            .dropFirst()
            .sink { [weak self] user in
                guard let self = self else { return }

                if user == nil {
                    if !self.userDidSignOut {
                        self.isSignInSheetPresented = true
                    }
                    self.handleUserSignedOut()
                } else {
                    self.userDidSignOut = false
                    self.handleUserSignedIn()
                }
            }
            .store(in: &cancellables)

        eventViewModel.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)

        ticketsViewModel.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)

        // UPDATED: Enhanced ticket change listener for burner mode
        ticketsViewModel.$tickets
            .dropFirst() // Skip initial empty state
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] tickets in
                guard let self = self else { return }
                
                // Check and schedule event day reminders
                self.burnerManager.checkAndScheduleEventDayReminder(tickets: tickets)
                
                // Check if burner mode monitoring should be active
                Task {
                    await self.burnerModeMonitor.checkNow()
                }
            }
            .store(in: &cancellables)
    }

    private func setupImagePrefetching() {
        imagePrefetchCancellable = eventViewModel.$events
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] events in
                guard self != nil else { return }
                let urls = events.compactMap { event -> URL? in
                    guard !event.imageUrl.isEmpty else { return nil }
                    return URL(string: event.imageUrl)
                }

                guard !urls.isEmpty else { return }

                let prefetcher = ImagePrefetcher(
                    urls: Array(urls.prefix(12)),
                    options: [
                        .downloadPriority(1.0),
                        .backgroundDecode
                    ]
                )
                prefetcher.start()
            }
    }

    private func setupBurnerModeObserver() {
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

        Task { @MainActor in
            let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
            if isEnabled {
                self.showingBurnerLockScreen = true
            }
        }
    }

    private func handleUserSignedIn() {
        Task {
            await eventViewModel.refreshEvents()
            ticketsViewModel.fetchUserTickets()
            bookmarkManager.refreshBookmarks()

            // IMPORTANT: Start burner mode monitoring after tickets are fetched
            // Give tickets time to load first
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            burnerModeMonitor.startMonitoring()
        }

        let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
        if isEnabled {
            showingBurnerLockScreen = true
        }

        Task {
            do {
                let profile = try await authService.getUserProfile()
                let isScanner = try await authService.isScannerActive()
                
                var finalRole: String = ""
                
                if let role = profile?.role {
                    finalRole = role
                } else if let fallbackRole = try? await authService.getUserRole() {
                    finalRole = fallbackRole
                }
                
                await MainActor.run {
                    self.userDisplayName = profile?.displayName ?? ""
                    self.userRole = finalRole
                    self.isScannerActive = isScanner
                }
            } catch {
                await MainActor.run {
                    self.userRole = ""
                    self.userDisplayName = ""
                    self.isScannerActive = false
                }
            }
        }
    }

    private func handleUserSignedOut() {
        ticketsViewModel.clearTickets()
        bookmarkManager.clearBookmarks()
        ticketsViewModel.cleanup()
        eventViewModel.cleanup()
        burnerModeMonitor.stopMonitoring()
        showingBurnerLockScreen = false
        userRole = ""
        userDisplayName = ""
        isScannerActive = false
    }

    func handleManualSignOut() {
        userDidSignOut = true
        isSignInSheetPresented = false
    }

    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    func clearError() {
        errorMessage = nil
        showingError = false
    }

    func loadInitialData() {
        Task {
            await eventViewModel.refreshEvents()
        }
    }

    func simulateEventBeforeStart() {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .hour, value: 2, to: now)!
        let endTime = calendar.date(byAdding: .hour, value: 6, to: now)!

        createDebugEvent(startTime: startTime, endTime: endTime)
    }

    func simulateEventDuringEvent() {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .hour, value: -1, to: now)!
        let endTime = calendar.date(byAdding: .hour, value: 3, to: now)!

        createDebugEvent(startTime: startTime, endTime: endTime)
    }

    private func createDebugEvent(startTime: Date, endTime: Date) {
        let now = Date()

        let testTicket = Ticket(
            eventId: "debug_event_\(UUID().uuidString)",
            userId: authService.currentUser?.id.uuidString ?? "debug_user",
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

        ticketsViewModel.addDebugTicket(testTicket)

        if #available(iOS 16.1, *) {
            let attributes = TicketActivityAttributes(
                eventName: testTicket.eventName,
                venue: testTicket.venue,
                startTime: testTicket.startTime,
                endTime: endTime,
                ticketId: testTicket.id ?? "test-ticket-id"
            )

            let now = Date()
            let hasStarted = now >= testTicket.startTime
            let hasEnded = now >= endTime
            let contentState = TicketActivityAttributes.ContentState(
                eventStartTime: testTicket.startTime,
                eventEndTime: endTime,
                hasEventStarted: hasStarted,
                hasEventEnded: hasEnded
            )

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
            } catch { }
        }
    }

    func clearDebugEventToday() {
        ticketsViewModel.removeDebugTickets()

        if #available(iOS 16.1, *) {
            TicketLiveActivityManager.endLiveActivity()
        }
    }

    func setBurnerSetupCompleted(_ completed: Bool) {
        burnerSetupCompleted = completed
        UserDefaults.standard.set(completed, forKey: "burnerSetupCompleted")
    }
    
    func syncBurnerModeAuthorization() {
        guard burnerManager.isAuthorized == false, burnerManager.isLocked else {
            return
        }

        Task { @MainActor in
            burnerManager.disable()
            self.showingBurnerLockScreen = false
        }
    }
}
