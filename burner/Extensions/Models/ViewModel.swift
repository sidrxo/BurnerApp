// ViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFunctions
import Combine
import UIKit
import FirebaseFirestore
import ActivityKit // Assuming this is needed based on AppState.swift

// MARK: - Refactored Event ViewModel
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
    
    // Task management for the real-time event listener
    private var eventObservationTask: Task<Void, Never>?
    
    // Track refresh state to prevent concurrent refreshes
    private var isRefreshing = false
    
    init(
        eventRepository: EventRepositoryProtocol,
        ticketRepository: TicketRepositoryProtocol
    ) {
        self.eventRepository = eventRepository
        self.ticketRepository = ticketRepository
    }
    
    // MARK: - Fetch Events (FIXED to use AsyncStream)
    func fetchEvents() {
        // 1. Cancel existing observation task to avoid multiple streams
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
        
        // 2. Create a new task to consume the AsyncStream
        eventObservationTask = Task { @MainActor in
            do {
                // 3. Loop through the stream for initial load and subsequent updates
                for try await events in eventRepository.eventStream(since: sevenDaysAgo) {
                    // Check for cancellation after receiving each yield
                    guard !Task.isCancelled else { return }
                    
                    // Filter out empty data simulation results
                    guard !self.isSimulatingEmptyData else { return }
                    
                    self.isLoading = false
                    self.events = events
                    
                    // Refresh ticket status after new events arrive
                    await self.refreshUserTicketStatus()
                }
            } catch {
                // Check for Task cancellation error before displaying
                if Task.isCancelled { return }
                
                self.isLoading = false
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Refresh Events (Improved for pull-to-refresh)
    func refreshEvents() async {
        guard !isSimulatingEmptyData else { return }
            
        // Prevent concurrent refresh operations
        guard !isRefreshing else { return }
        isRefreshing = true
            
        defer {
            Task { @MainActor in
                self.isRefreshing = false
            }
        }

        // Clear any existing errors
        await MainActor.run {
            self.errorMessage = nil
        }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        do {
            // Fetch fresh data from server (This is a one-time operation, correct for try await)
            let serverEvents = try await eventRepository.fetchEventsFromServer(since: sevenDaysAgo)

            await MainActor.run {
                // Update events with fresh server data
                self.events = serverEvents
            }

            // Refresh ticket status in background
            await self.refreshUserTicketStatus()

        } catch {
            // Only show error if it's not a cancellation error
            let nsError = error as NSError
                
            // Ignore cancellation errors (they're harmless)
            if nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
                return
            }
                
            // Ignore network connection errors during refresh (user likely knows)
            if nsError.domain == NSURLErrorDomain &&
                (nsError.code == NSURLErrorNotConnectedToInternet ||
                 nsError.code == NSURLErrorNetworkConnectionLost) {
                return
            }
                
            // Only show other errors
            await MainActor.run {
                self.errorMessage = "Failed to refresh: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Debug helpers
        
    func simulateEmptyData() {
        eventObservationTask?.cancel() // Stop the real-time listener/task
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
        fetchEvents() // Restart the real-time listener
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
            
        // ✅ FIX: Add the fetched event to the published array
        await MainActor.run {
            // Check if it already exists and update, otherwise append
            if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                self.events[index] = event // Update existing
            } else {
                self.events.append(event) // Add new
            }
        }
            
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
        
    var featuredEvents: [Event] {
        let featured = events.filter { $0.isFeatured == true }
        return Array(featured.prefix(5))
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
        // CANCELLING THE TASK ALSO STOPS THE UNDERLYING FIREBASE LISTENER
        eventObservationTask?.cancel()
        cancellables.removeAll()
    }
}

// MARK: - Tickets ViewModel
@MainActor
class TicketsViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let ticketRepository: TicketRepositoryProtocol
    private var isSimulatingEmptyData = false
    private var ticketObservationListener: ListenerRegistration? // For the callback-based listener
        
    init(ticketRepository: TicketRepositoryProtocol) {
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
        
        // NOTE: This uses the old completion handler from TicketRepository
        // A future improvement would be to refactor this to an AsyncStream as well.
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
