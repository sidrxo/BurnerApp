import Foundation
import Supabase
import Combine
import UIKit
import ActivityKit

@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var userTicketStatus: [String: Bool] = [:]

    private let eventRepository: EventRepositoryProtocol
    private let ticketRepository: TicketRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var isSimulatingEmptyData = false
    
    private weak var ticketsViewModel: TicketsViewModel?
    private var eventObservationTask: Task<Void, Never>?
        
    init(
        eventRepository: EventRepositoryProtocol,
        ticketRepository: TicketRepositoryProtocol
    ) {
        self.eventRepository = eventRepository
        self.ticketRepository = ticketRepository
    }
    
    func setTicketsViewModel(_ viewModel: TicketsViewModel) {
        self.ticketsViewModel = viewModel
        setupTicketStatusListener()
    }
    
    private func setupTicketStatusListener() {
        ticketsViewModel?.$tickets
            .sink { [weak self] tickets in
                guard let self = self else { return }
                
                var newStatus: [String: Bool] = [:]
                
                for event in self.events {
                    if let eventId = event.id {
                        newStatus[eventId] = false
                    }
                }
                
                for ticket in tickets where ticket.status == "confirmed" {
                    newStatus[ticket.eventId] = true
                }
                
                self.userTicketStatus = newStatus
            }
            .store(in: &cancellables)
    }
    
    func fetchEvents() {
        eventObservationTask?.cancel()
        
        guard !isSimulatingEmptyData else {
            isLoading = false
            events = []
            userTicketStatus = [:]
            return
        }

        isLoading = true
        errorMessage = nil

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        eventObservationTask = Task { @MainActor in
            do {
                for try await events in eventRepository.eventStream(since: sevenDaysAgo) {
                    guard !Task.isCancelled else { return }
                    
                    guard !self.isSimulatingEmptyData else { return }
                    
                    self.isLoading = false
                    self.events = events
                    
                    await self.refreshUserTicketStatus()
                }
            } catch {
                if Task.isCancelled { return }
                
                self.isLoading = false
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
            }
        }
    }

    func refreshEvents() async {
        guard !isSimulatingEmptyData else { return }
        
        await MainActor.run {
            self.errorMessage = nil
        }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        do {
            let serverEvents = try await eventRepository.fetchEventsFromServer(
                            since: sevenDaysAgo,
                            page: 1,
                            pageSize: 100)

            await MainActor.run {
                self.events = serverEvents
            }

            await self.refreshUserTicketStatus()

        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            
            let nsError = error as NSError
                
            if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
                return
            }
                
            if nsError.domain == NSURLErrorDomain &&
                (nsError.code == NSURLErrorNotConnectedToInternet ||
                 nsError.code == NSURLErrorNetworkConnectionLost) {
                return
            }
                
            await MainActor.run {
                self.errorMessage = "Failed to refresh: \(error.localizedDescription)"
            }
        }
    }
        
    func simulateEmptyData() {
        eventObservationTask?.cancel()
        isSimulatingEmptyData = true
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
        guard let event = try await eventRepository.fetchEvent(by: eventId) else {
             throw NSError(domain: "EventViewModel", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Event not found"
            ])
        }
            
        await MainActor.run {
            if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                self.events[index] = event
            } else {
                self.events.append(event)
            }
        }
            
        return event
    }
        
    func refreshUserTicketStatus() async {
        guard let user = try? await SupabaseManager.shared.client.auth.session.user else {
            userTicketStatus.removeAll()
            return
        }
            
        let eventIds = events.compactMap { $0.id }
            
        do {
            let status = try await ticketRepository.fetchUserTicketStatus(
                userId: user.id.uuidString,
                eventIds: eventIds
            )
                
            await MainActor.run {
                self.userTicketStatus = status
            }
        } catch {
            // Silent fail - status will be updated by ticket listener
        }
    }
        
    var featuredEvents: [Event] {
        let featured = events.filter { $0.isFeatured == true }
        return Array(featured.prefix(5))
    }
        
    func checkUserTicketStatus(for eventId: String, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                guard let user = try? await SupabaseManager.shared.client.auth.session.user else {
                    completion(false)
                    return
                }
                
                let hasTicket = try await ticketRepository.userHasTicket(
                    userId: user.id.uuidString,
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
        
    func userHasTicket(for eventId: String) -> Bool {
        return userTicketStatus[eventId] ?? false
    }
        
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
        
    func cleanup() {
        eventObservationTask?.cancel()
        cancellables.removeAll()
    }
}
@MainActor
class TicketsViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let ticketRepository: TicketRepositoryProtocol
    private var isSimulatingEmptyData = false
        
    init(ticketRepository: TicketRepositoryProtocol) {
        self.ticketRepository = ticketRepository
    }
        
    func fetchUserTickets() {
        guard !isSimulatingEmptyData else {
            isLoading = false
            tickets = []
            return
        }

        Task {
            do {
                guard let user = try? await SupabaseManager.shared.client.auth.session.user else {
                    isLoading = false
                    return
                }

                if self.tickets.isEmpty {
                    isLoading = true
                }
                
                ticketRepository.observeUserTickets(userId: user.id.uuidString) { [weak self] result in
                    guard let self = self else { return }

                    Task { @MainActor in
                        guard !self.isSimulatingEmptyData else { return }

                        self.isLoading = false

                        switch result {
                        case .success(let tickets):
                            self.tickets = tickets
                            self.errorMessage = nil

                        case .failure(let error):
                            // MARK: - FIX STARTS HERE
                            // Check for various cancellation types to avoid showing alerts for them
                            let nsError = error as NSError
                            if error is CancellationError ||
                               nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled ||
                               nsError.localizedDescription.lowercased() == "cancelled" {
                                print("Ticket fetch cancelled silently.")
                                return
                            }
                            // MARK: - FIX ENDS HERE

                            Task {
                                if let _ = try? await SupabaseManager.shared.client.auth.session.user {
                                    self.errorMessage = "Failed to load tickets: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ... (Keep the rest of your methods: clearTickets, simulateEmptyData, etc. exactly the same) ...
    
    func clearTickets() {
        tickets = []
        errorMessage = nil
    }
        
    func simulateEmptyData() {
        ticketRepository.stopObserving()
        isSimulatingEmptyData = true
        tickets = []
        isLoading = false
        errorMessage = nil
    }
        
    func resumeFromSimulation() {
        guard isSimulatingEmptyData else { return }
        isSimulatingEmptyData = false
        fetchUserTickets()
    }
        
    func addDebugTicket(_ ticket: Ticket) {
        self.tickets.append(ticket)
            
        self.tickets.sort { ticket1, ticket2 in
            ticket1.startTime < ticket2.startTime
        }
    }
        
    func removeDebugTickets() {
        self.tickets.removeAll { ticket in
            ticket.id?.hasPrefix("debug_ticket_") == true ||
            ticket.eventId.hasPrefix("debug_event_")
        }
    }

    func cleanup() {
        ticketRepository.stopObserving()
        clearTickets()
    }
}
