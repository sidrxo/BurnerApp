import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth
import Combine

@MainActor
class EventViewModel: ObservableObject, Sendable {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var userTicketStatus: [String: Bool] = [:] // eventId -> hasTicket
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    init() {
        configureFunctions()
    }
    
    private func configureFunctions() {
        #if DEBUG
        // Uncomment if using local emulator
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif
        
        // Set proper region if your functions are not in us-central1
        // functions = Functions.functions(region: "your-region")
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    func fetchEvents() {
        isLoading = true
        
        db.collection("events")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Failed to load events: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.events = []
                        return
                    }
                    
                    self?.events = documents.compactMap { doc in
                        do {
                            var event = try doc.data(as: Event.self)
                            event.id = doc.documentID
                            return event
                        } catch {
                            return nil
                        }
                    }
                    
                    // Check user's ticket status for all events
                    self?.checkUserTicketStatusForAllEvents()
                }
            }
    }
    
    private func checkUserTicketStatusForAllEvents() {
        guard Auth.auth().currentUser != nil else { return }
        
        for event in events {
            if let eventId = event.id {
                checkUserTicketStatus(for: eventId) { [weak self] hasTicket in
                    Task { @MainActor in
                        self?.userTicketStatus[eventId] = hasTicket
                    }
                }
            }
        }
    }
    
    func checkUserTicketStatus(for eventId: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        user.getIDTokenForcingRefresh(true) { [weak self] token, error in
            if error != nil || token == nil {
                completion(false)
                return
            }
            
            let checkData: [String: Any] = [
                "eventId": eventId
            ]
            
            self?.functions.httpsCallable("checkUserTicket").call(checkData) { result, error in
                if let error = error {
                    print("Error checking ticket status: \(error.localizedDescription)")
                    completion(false)
                } else if let data = result?.data as? [String: Any],
                          let hasTicket = data["hasTicket"] as? Bool {
                    completion(hasTicket)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func userHasTicket(for eventId: String) -> Bool {
        return userTicketStatus[eventId] ?? false
    }
    
    func purchaseTicket(eventId: String, completion: @escaping (Bool, String?) -> Void) {
        // Check if user already has a ticket for this event
        if userHasTicket(for: eventId) {
            completion(false, "You already have a ticket for this event")
            return
        }
        
        // Ensure user is authenticated
        guard let user = Auth.auth().currentUser else {
            completion(false, "Please log in to purchase a ticket")
            return
        }
        
        // Get fresh ID token to ensure auth context is properly set
        user.getIDTokenForcingRefresh(true) { [weak self] token, error in
            if error != nil {
                completion(false, "Authentication error. Please try logging out and back in.")
                return
            }
            
            guard token != nil else {
                completion(false, "Failed to get authentication token")
                return
            }
            
            // Call Cloud Function with proper auth context
            let purchaseData: [String: Any] = [
                "eventId": eventId
            ]
            
            self?.functions.httpsCallable("purchaseTicket").call(purchaseData) { result, error in
                Task { @MainActor in
                    if let error = error as NSError? {
                        let errorMsg = self?.handleFunctionError(error) ?? "Purchase failed"
                        self?.errorMessage = errorMsg
                        completion(false, errorMsg)
                    } else if let data = result?.data as? [String: Any] {
                        if let success = data["success"] as? Bool, success {
                            let message = data["message"] as? String ?? "Ticket purchased successfully!"
                            self?.successMessage = message
                            // Update user ticket status
                            self?.userTicketStatus[eventId] = true
                            completion(true, message)
                            self?.fetchEvents() // Refresh events to update ticket counts
                        } else {
                            let errorMsg = data["message"] as? String ?? "Purchase failed"
                            self?.errorMessage = errorMsg
                            completion(false, errorMsg)
                        }
                    } else {
                        let errorMsg = "Unexpected response from server"
                        self?.errorMessage = errorMsg
                        completion(false, errorMsg)
                    }
                }
            }
        }
    }
    
    private func handleFunctionError(_ error: NSError) -> String {
        switch error.code {
        case FunctionsErrorCode.unauthenticated.rawValue:
            return "Authentication failed. Please log out and log back in."
        case FunctionsErrorCode.permissionDenied.rawValue:
            return "Permission denied. Please check your account."
        case FunctionsErrorCode.notFound.rawValue:
            return "Event not found."
        case FunctionsErrorCode.invalidArgument.rawValue:
            return "Invalid purchase details."
        case FunctionsErrorCode.failedPrecondition.rawValue:
            // This could be either "sold out" or "already has ticket"
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
}
