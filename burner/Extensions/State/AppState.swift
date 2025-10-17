// PART 1: Update AppState.swift

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
    
    // ✅ NEW: Track if user manually signed out
    @Published var userDidSignOut = false
    
    // Add flag to track initial auth check
    private var hasCompletedInitialAuthCheck = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Shared repository instances
    private let eventRepository: EventRepository
    private let ticketRepository: TicketRepository
    private let bookmarkRepository: BookmarkRepository
    private let userRepository: UserRepository
    private let purchaseService: PurchaseService
    
    init() {
        // Initialize repositories (shared instances)
        self.eventRepository = EventRepository()
        self.ticketRepository = TicketRepository()
        self.bookmarkRepository = BookmarkRepository()
        self.userRepository = UserRepository()
        
        // Initialize services
        self.purchaseService = PurchaseService()
        
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
    
    // ✅ NEW: Method to handle manual sign out
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

