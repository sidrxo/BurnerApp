import Foundation
import FirebaseAuth
import FirebaseFunctions
import Combine
import UIKit

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
    private let purchaseService: PurchaseService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        eventRepository: EventRepository,
        ticketRepository: TicketRepository,
        purchaseService: PurchaseService
    ) {
        self.eventRepository = eventRepository
        self.ticketRepository = ticketRepository
        self.purchaseService = purchaseService
    }
    
    // MARK: - Fetch Events
    func fetchEvents() {
        isLoading = true
        
        eventRepository.observeEvents { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
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
    
    // MARK: - Purchase Ticket
    func purchaseTicket(eventId: String, completion: @escaping (Bool, String?) -> Void) {
        if userHasTicket(for: eventId) {
            completion(false, "Ticket Purchased")
            return
        }
        
        guard Auth.auth().currentUser != nil else {
            completion(false, "Please log in to purchase a ticket")
            return
        }
        
        Task {
            do {
                let result = try await purchaseService.purchaseTicket(eventId: eventId)
                
                await MainActor.run {
                    if result.success {
                        self.successMessage = result.message
                        self.userTicketStatus[eventId] = true
                        self.fetchEvents() // Refresh to update sold count
                        completion(true, result.message)
                    } else {
                        self.errorMessage = result.message
                        completion(false, result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    let errorMsg = self.handleError(error)
                    self.errorMessage = errorMsg
                    completion(false, errorMsg)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) -> String {
        if let nsError = error as NSError? {
            switch nsError.code {
            case FunctionsErrorCode.unauthenticated.rawValue:
                return "Authentication failed. Please log out and log back in."
            case FunctionsErrorCode.permissionDenied.rawValue:
                return "Permission denied. Please check your account."
            case FunctionsErrorCode.notFound.rawValue:
                return "Event not found."
            case FunctionsErrorCode.invalidArgument.rawValue:
                return "Invalid purchase details."
            case FunctionsErrorCode.failedPrecondition.rawValue:
                return error.localizedDescription.contains("already have") ?
                    "You already have a ticket for this event" :
                    "Event sold out or unavailable."
            case FunctionsErrorCode.internal.rawValue:
                return "Server error. Please try again."
            case FunctionsErrorCode.unavailable.rawValue:
                return "Service temporarily unavailable. Please try again."
            case FunctionsErrorCode.deadlineExceeded.rawValue:
                return "Request timed out. Please try again."
            default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
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

// MARK: - Refactored Bookmark Manager


// MARK: - Tickets ViewModel
@MainActor
class TicketsViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let ticketRepository: TicketRepository
    
    init(ticketRepository: TicketRepository) {
        self.ticketRepository = ticketRepository
    }
    
    // MARK: - Fetch User Tickets
    func fetchUserTickets() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Don't set error message when user is not authenticated
            isLoading = false
            return
        }

        isLoading = true

        ticketRepository.observeUserTickets(userId: userId) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
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

    // MARK: - Cleanup
    func cleanup() {
        ticketRepository.stopObserving()
        clearTickets()
    }
}
