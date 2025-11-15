import Foundation
import FirebaseAuth
import FirebaseFunctions
import Combine
import UIKit
import FirebaseFirestore

// MARK: - Refactored Event ViewModel
@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var userTicketStatus: [String: Bool] = [:]

    private let eventRepository: EventRepository
    private let ticketRepository: TicketRepository
    private var cancellables = Set<AnyCancellable>()
    private var isSimulatingEmptyData = false
    
    init(
        eventRepository: EventRepository,
        ticketRepository: TicketRepository
    ) {
        self.eventRepository = eventRepository
        self.ticketRepository = ticketRepository
    }
    
    // MARK: - Fetch Events
    func fetchEvents() {
        guard !isSimulatingEmptyData else {
            isLoading = false
            events = []
            userTicketStatus = [:]
            return
        }

        isLoading = true

        eventRepository.observeEvents { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                guard !self.isSimulatingEmptyData else { return }

                self.isLoading = false

                switch result {
                case .success(let events):
                    self.events = events
                    await self.refreshUserTicketStatus()

                case .failure(let error):
                    self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Refresh Events (Force refresh by restarting listener)
    func refreshEvents() async {
        guard !isSimulatingEmptyData else { return }

        // Stop the existing listener
        eventRepository.stopObserving()

        // Small delay to ensure clean restart
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Restart the listener
        fetchEvents()
    }

    // MARK: - Debug helpers
    
    func simulateEmptyData() {
        isSimulatingEmptyData = true
        eventRepository.stopObserving()
        events = []
        userTicketStatus = [:]
        isLoading = false
        errorMessage = nil
        successMessage = nil
    }

    func resumeFromSimulation() {
        guard isSimulatingEmptyData else { return }
        isSimulatingEmptyData = false
        fetchEvents()
    }
    
    
    func fetchEvent(byId eventId: String) async throws -> Event {
        let db = Firestore.firestore()
        let documentSnapshot = try await db.collection("events").document(eventId).getDocument()
        
        guard documentSnapshot.exists else {
            throw NSError(domain: "EventViewModel", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Event not found"
            ])
        }
        
        guard var event = try? documentSnapshot.data(as: Event.self) else {
            throw NSError(domain: "EventViewModel", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode event"
            ])
        }
        
        event.id = documentSnapshot.documentID
        return event
    }
    
    // MARK: - Refresh User Ticket Status
    private func refreshUserTicketStatus() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            userTicketStatus.removeAll()
            return
        }
        
        let eventIds = events.compactMap { $0.id }
        
        do {
            let status = try await ticketRepository.fetchUserTicketStatus(
                userId: userId,
                eventIds: eventIds
            )
            
            // Update on main actor
            await MainActor.run {
                self.userTicketStatus = status
            }
        } catch {
            // Silently fail for ticket status check
        }
    }
    
    // MARK: - Check Single Ticket Status
    func checkUserTicketStatus(for eventId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        Task {
            do {
                let hasTicket = try await ticketRepository.userHasTicket(
                    userId: userId,
                    eventId: eventId
                )
                
                await MainActor.run {
                    self.userTicketStatus[eventId] = hasTicket
                    completion(hasTicket)
                }
            } catch {
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - User Has Ticket
    func userHasTicket(for eventId: String) -> Bool {
        return userTicketStatus[eventId] ?? false
    }
    
    // MARK: - Clear Messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Cleanup
    func cleanup() {
        eventRepository.stopObserving()
        cancellables.removeAll()
    }
}

// MARK: - Tickets ViewModel
@MainActor
class TicketsViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let ticketRepository: TicketRepository
    private var isSimulatingEmptyData = false
    
    init(ticketRepository: TicketRepository) {
        self.ticketRepository = ticketRepository
    }
    
    // MARK: - Fetch User Tickets
    func fetchUserTickets() {
        guard !isSimulatingEmptyData else {
            isLoading = false
            tickets = []
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            // Don't set error message when user is not authenticated
            isLoading = false
            return
        }

        isLoading = true

        ticketRepository.observeUserTickets(userId: userId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                guard !self.isSimulatingEmptyData else { return }

                self.isLoading = false

                switch result {
                case .success(let tickets):
                    self.tickets = tickets

                case .failure(let error):
                    // Only show error if user is still authenticated
                    if Auth.auth().currentUser != nil {
                        self.errorMessage = "Failed to load tickets: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - Clear Tickets
    func clearTickets() {
        tickets = []
        errorMessage = nil
    }



    // MARK: - Debug helpers
    
    func simulateEmptyData() {
        isSimulatingEmptyData = true
        ticketRepository.stopObserving()
        tickets = []
        isLoading = false
        errorMessage = nil
    }
    

    func resumeFromSimulation() {
        guard isSimulatingEmptyData else { return }
        isSimulatingEmptyData = false
        fetchUserTickets()
    }
    
    // MARK: - Debug Methods for Live Activity Testing
    
    /// Adds a debug ticket to the tickets list for testing purposes
    func addDebugTicket(_ ticket: Ticket) {
        // Add to the tickets array
        self.tickets.append(ticket)
        
        // Sort by event start time to keep it organized
        self.tickets.sort { ticket1, ticket2 in
            ticket1.startTime < ticket2.startTime
        }
    }
    
    /// Removes all debug tickets (those with IDs starting with "debug_")
    func removeDebugTickets() {
        self.tickets.removeAll { ticket in
            ticket.id?.hasPrefix("debug_ticket_") == true ||
            ticket.eventId.hasPrefix("debug_event_")
        }
    }

    // MARK: - Cleanup
    func cleanup() {
        ticketRepository.stopObserving()
        clearTickets()
    }
}
