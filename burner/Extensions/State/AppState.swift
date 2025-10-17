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
    
    // MARK: - Global UI State
    @Published var isSignInSheetPresented = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize repositories (shared instances)
        let eventRepository = EventRepository()
        let ticketRepository = TicketRepository()
        let bookmarkRepository = BookmarkRepository()
        let userRepository = UserRepository()
        
        // Initialize services
        let purchaseService = PurchaseService()
        
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
        
        setupObservers()
    }
    
    // MARK: - Setup Observers
    private func setupObservers() {
        // Observe authentication state
        authService.$currentUser
            .sink { [weak self] user in
                if user == nil {
                    self?.isSignInSheetPresented = true
                    self?.handleUserSignedOut()
                } else {
                    self?.handleUserSignedIn()
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
    
    // MARK: - User Sign In/Out Handlers
    private func handleUserSignedIn() {
        // Fetch data when user signs in
        eventViewModel.fetchEvents()
        ticketsViewModel.fetchUserTickets()
    }
    
    private func handleUserSignedOut() {
        // Clear all user-specific data
        bookmarkManager.clearBookmarks()
        ticketsViewModel.cleanup()
        eventViewModel.cleanup()
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
