import SwiftUI
import Combine
import Shared

@MainActor
class AppState: ObservableObject {
    // MARK: - ViewModels
    @Published var eventViewModel: EventViewModel
    @Published var ticketsViewModel: TicketsViewModel // ✅ Uncommented
    @Published var bookmarkManager: BookmarkManager
    @Published var onboardingManager: OnboardingManager
    
    // MARK: - Managers
    // ✅ Added BurnerModeManager (Swift-only manager)
    let burnerManager = BurnerModeManager()
    
    // Services & Repos
    let authService: Shared.AuthService
    let eventRepository: Shared.EventRepository
    let ticketRepository: Shared.TicketRepository
    let bookmarkRepository: Shared.BookmarkRepository
    let userRepository: Shared.UserRepository
    
    @Published var showingBurnerLockScreen = false
    @Published var burnerSetupCompleted = false
    
    init() {
        // 1. Initialize KMP
        let url = "https://lsqlgyyugysvhvxtssik.supabase.co"
        let key = "sb_publishable_gSNN1pd-OujICXo_6_WmUg_5rhwRw3L"
        KmpHelper.shared.initialize(url: url, key: key)
        
        self.authService = KmpHelper.shared.getAuthService()
        self.eventRepository = KmpHelper.shared.getEventRepository()
        self.ticketRepository = KmpHelper.shared.getTicketRepository()
        self.bookmarkRepository = KmpHelper.shared.getBookmarkRepository()
        self.userRepository = KmpHelper.shared.getUserRepository()
        
        // 2. Initialize ViewModels
        self.ticketsViewModel = TicketsViewModel(
            ticketRepository: ticketRepository,
            eventRepository: eventRepository
        )
        
        self.eventViewModel = EventViewModel(
            eventRepository: eventRepository,
            ticketRepository: ticketRepository
        )
        // Link them
        self.eventViewModel.setTicketsViewModel(ticketsViewModel)
        
        self.bookmarkManager = BookmarkManager(
            bookmarkRepository: bookmarkRepository,
            eventViewModel: eventViewModel
        )
        
        self.onboardingManager = OnboardingManager(authService: authService)
    }
}
