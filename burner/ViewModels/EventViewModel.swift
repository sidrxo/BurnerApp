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
    private var functions = Functions.functions()
    private var hasConfiguredFunctions = false
    
    init() {
        configureFunctions()
    }
    
    private func configureFunctions() {
        if hasConfiguredFunctions { return }
        
        #if DEBUG
        // Configure for local development if needed
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif
        
        // Ensure we're using the correct region
        functions = Functions.functions(region: "us-central1")
        hasConfiguredFunctions = true
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    func fetchEvents() {
        isLoading = true
        
        db.collection("events")
            .order(by: "date", descending: false)
            .addSnapshotListener { snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.events = []
                        return
                    }
                    
                    self.events = documents.compactMap { doc in
                        do {
                            var event = try doc.data(as: Event.self)
                            event.id = doc.documentID
                            return event
                        } catch {
                            return nil
                        }
                    }
                    
                    // Fetch user's ticket status efficiently from Firestore
                    self.fetchUserTicketStatusFromFirestore()
                }
            }
    }
    
    private func fetchUserTicketStatusFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            userTicketStatus.removeAll()
            return
        }
        
        db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments { snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    
                    if let error = error {
                        print("Error fetching user tickets: \(error.localizedDescription)")
                        return
                    }
                    
                    // Create set of event IDs user has tickets for
                    let eventIdsWithTickets = Set(snapshot?.documents.compactMap { doc -> String? in
                        doc.data()["eventId"] as? String
                    } ?? [])
                    
                    // Update status for all events
                    self.userTicketStatus.removeAll()
                    for event in self.events {
                        if let eventId = event.id {
                            self.userTicketStatus[eventId] = eventIdsWithTickets.contains(eventId)
                        }
                    }
                }
            }
    }
    
    func checkUserTicketStatus(for eventId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        // Query Firestore directly instead of using Cloud Function
        db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .whereField("eventId", isEqualTo: eventId)
            .whereField("status", isEqualTo: "confirmed")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error checking ticket status: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    let hasTicket = !(snapshot?.documents.isEmpty ?? true)
                    self?.userTicketStatus[eventId] = hasTicket
                    completion(hasTicket)
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
            guard let self else {
                completion(false, "Session expired")
                return
            }
            
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
            
            self.functions.httpsCallable("purchaseTicket").call(purchaseData) { result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    
                    if let error = error as NSError? {
                        let errorMsg = self.handleFunctionError(error)
                        self.errorMessage = errorMsg
                        completion(false, errorMsg)
                    } else if let data = result?.data as? [String: Any] {
                        if let success = data["success"] as? Bool, success {
                            let message = data["message"] as? String ?? "Ticket purchased successfully!"
                            self.successMessage = message
                            // Update user ticket status
                            self.userTicketStatus[eventId] = true
                            completion(true, message)
                            self.fetchEvents() // Refresh events to update ticket counts
                        } else {
                            let errorMsg = data["message"] as? String ?? "Purchase failed"
                            self.errorMessage = errorMsg
                            completion(false, errorMsg)
                        }
                    } else {
                        let errorMsg = "Unexpected response from server"
                        self.errorMessage = errorMsg
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
