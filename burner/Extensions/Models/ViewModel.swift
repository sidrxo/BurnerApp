import Foundation
import Combine
import Shared

@MainActor
class TicketsViewModel: ObservableObject {
    @Published var tickets: [Shared.Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let ticketRepository: Shared.TicketRepository
    private let eventRepository: Shared.EventRepository
    
    init(ticketRepository: Shared.TicketRepository, eventRepository: Shared.EventRepository) {
        self.ticketRepository = ticketRepository
        self.eventRepository = eventRepository
        
        Task { await fetchTickets() }
    }
    
    func fetchTickets() async {
        guard let userId = KmpHelper.shared.getAuthService().getCurrentUserId() else { return }
        
        isLoading = true
        do {
            let fetchedTickets = try await ticketRepository.fetchUserTickets(userId: userId)
            self.tickets = fetchedTickets
        } catch {
            print("Error fetching tickets: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func refresh() async {
        await fetchTickets()
    }
    
    // Helper to clear tickets on logout
    func clearTickets() {
        self.tickets = []
    }
    
    // Debug helpers (keep for compilation safety)
    func removeDebugTickets() {
        // Logic to remove debug tickets if implemented
    }
}
