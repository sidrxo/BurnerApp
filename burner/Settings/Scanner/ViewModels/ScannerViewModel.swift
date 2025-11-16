import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import AVFoundation

/// Handles all business logic for the scanner feature
@MainActor
class ScannerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isCheckingScanner = true
    @Published var isScannerActive = false
    @Published var userRole: String = ""
    @Published var selectedEvent: Event?
    @Published var todaysEvents: [Event] = []
    @Published var isLoadingEvents = false
    @Published var isProcessing = false

    // Alert states
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingSuccess = false
    @Published var successMessage = ""
    @Published var showingAlreadyUsed = false
    @Published var alreadyUsedDetails: AlreadyUsedTicket?

    // MARK: - Dependencies
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west2")
    private let selectedEventIdKey = "selectedScannerEventId"

    // MARK: - Computed Properties
    var canScanTickets: Bool {
        userRole == "scanner" || userRole == "venueAdmin" || userRole == "siteAdmin"
    }

    // MARK: - Initialization
    func onAppear() {
        fetchUserRoleFromClaims()
        checkScannerAccessFromClaims()
        fetchTodaysEvents()
        loadPersistedEventSelection()
    }

    // MARK: - Permission & Role Management
    func checkScannerAccessFromClaims() {
        guard let user = Auth.auth().currentUser else {
            print("🔍 [SCANNER DEBUG] ❌ No user authenticated")
            isCheckingScanner = false
            isScannerActive = false
            return
        }

        print("🔍 [SCANNER DEBUG] Checking scanner access for user: \(user.uid)")

        user.getIDTokenResult { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isCheckingScanner = false

                if let error = error {
                    print("🔍 [SCANNER DEBUG] ❌ Error getting token: \(error.localizedDescription)")
                    self.isScannerActive = false
                    return
                }

                if let claims = result?.claims,
                   let role = claims["role"] as? String {
                    print("🔍 [SCANNER DEBUG] ✅ User role from claims: \(role)")
                    self.userRole = role
                    self.isScannerActive = (role == "scanner" || role == "admin" || role == "siteadmin")
                    print("🔍 [SCANNER DEBUG] Scanner active: \(self.isScannerActive)")
                } else {
                    print("🔍 [SCANNER DEBUG] ⚠️ No role claim found")
                    self.isScannerActive = false
                }
            }
        }
    }

    func fetchUserRoleFromClaims() {
        guard let user = Auth.auth().currentUser else { return }

        user.getIDTokenResult { [weak self] result, error in
            if let claims = result?.claims,
               let role = claims["role"] as? String {
                Task { @MainActor in
                    self?.userRole = role
                }
            }
        }
    }

    // MARK: - Event Management
    func fetchTodaysEvents() {
        isLoadingEvents = true

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        print("🔍 [SCANNER DEBUG] Fetching events for today...")

        db.collection("events")
            .whereField("startTime", isGreaterThanOrEqualTo: today)
            .whereField("startTime", isLessThan: tomorrow)
            .whereField("status", isEqualTo: "active")
            .getDocuments { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isLoadingEvents = false

                    if let error = error {
                        print("🔍 [SCANNER DEBUG] ❌ Error fetching events: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("🔍 [SCANNER DEBUG] No events found for today")
                        return
                    }

                    self.todaysEvents = documents.compactMap { doc in
                        try? doc.data(as: Event.self)
                    }.sorted { (event1, event2) in
                        guard let start1 = event1.startTime, let start2 = event2.startTime else {
                            return false
                        }
                        return start1 < start2
                    }

                    print("🔍 [SCANNER DEBUG] Found \(self.todaysEvents.count) events for today")

                    // Restore persisted event selection after events are loaded
                    self.loadPersistedEventSelection()
                }
            }
    }

    func selectEvent(_ event: Event) {
        selectedEvent = event
        if let eventId = event.id {
            UserDefaults.standard.set(eventId, forKey: selectedEventIdKey)
        }
    }

    func clearEventSelection() {
        selectedEvent = nil
        UserDefaults.standard.removeObject(forKey: selectedEventIdKey)
    }

    private func loadPersistedEventSelection() {
        guard let eventId = UserDefaults.standard.string(forKey: selectedEventIdKey) else { return }

        // Find the event in today's events once they're loaded
        if let event = todaysEvents.first(where: { $0.id == eventId }) {
            selectedEvent = event
        }
    }

    // MARK: - Ticket Scanning

    /// Determines the ticket ID from either QR code or manual entry
    func determineTicketId(qrCodeData: String? = nil, manualTicketId: String? = nil) -> String? {
        print("🔍 [SCANNER DEBUG] === DETERMINING TICKET ID ===")
        print("🔍 [SCANNER DEBUG] QR Data: \(qrCodeData ?? "nil")")
        print("🔍 [SCANNER DEBUG] Manual Ticket ID: \(manualTicketId ?? "nil")")

        // Priority: manual entry > extracted from QR > raw QR data
        if let ticketId = manualTicketId {
            print("🔍 [SCANNER DEBUG] Using manual ticket ID: \(ticketId)")
            return ticketId
        } else if let qrData = qrCodeData, let extracted = extractTicketId(from: qrData) {
            print("🔍 [SCANNER DEBUG] Extracted ticket ID from QR: \(extracted)")
            return extracted
        } else if let qrData = qrCodeData {
            print("🔍 [SCANNER DEBUG] Using raw QR data as ticket ID: \(qrData)")
            return qrData
        }

        print("🔍 [SCANNER DEBUG] ❌ No valid ticket data provided")
        return nil
    }

    /// Extracts ticket ID from partypass.com URL
    private func extractTicketId(from qrData: String) -> String? {
        print("🔍 [SCANNER DEBUG] Attempting to extract ticket ID from: \(qrData)")

        if let url = URL(string: qrData),
           url.scheme == "https",
           url.host == "partypass.com" || url.host == "www.partypass.com",
           url.pathComponents.contains("ticket") {

            if let ticketId = url.pathComponents.last {
                print("🔍 [SCANNER DEBUG] ✅ Extracted ticket ID from URL: \(ticketId)")
                return ticketId
            }
        }

        print("🔍 [SCANNER DEBUG] ⚠️ Could not extract ticket ID from URL")
        return nil
    }

    /// Main scan orchestration method
    func scanTicket(qrCodeData: String? = nil, manualTicketId: String? = nil) {
        guard !isProcessing else {
            print("🔍 [SCANNER DEBUG] ⚠️ Already processing a scan")
            return
        }

        guard let selectedEvent = selectedEvent, let eventId = selectedEvent.id else {
            print("🔍 [SCANNER DEBUG] ❌ No event selected")
            errorMessage = "Please select an event first"
            showingError = true
            return
        }

        guard let ticketId = determineTicketId(qrCodeData: qrCodeData, manualTicketId: manualTicketId),
              !ticketId.isEmpty else {
            errorMessage = "Invalid ticket data"
            showingError = true
            return
        }

        print("🔍 [SCANNER DEBUG] Final Ticket ID: \(ticketId)")
        print("🔍 [SCANNER DEBUG] Selected Event ID: \(eventId)")

        isProcessing = true

        callScanFunction(ticketId: ticketId, eventId: eventId, qrCodeData: qrCodeData) { [weak self] result in
            Task { @MainActor in
                self?.handleScanResult(result)
            }
        }
    }

    /// Calls the Cloud Function to scan the ticket
    private func callScanFunction(
        ticketId: String,
        eventId: String,
        qrCodeData: String?,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        let scanFunction = functions.httpsCallable("scanTicket")
        let data: [String: Any] = [
            "ticketId": ticketId,
            "eventId": eventId,
            "qrCodeData": qrCodeData as Any
        ]

        print("🔍 [SCANNER DEBUG] Calling cloud function with data: \(data)")

        scanFunction.call(data) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = result?.data as? [String: Any] {
                completion(.success(data))
            } else {
                let invalidResponseError = NSError(
                    domain: "ScannerViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"]
                )
                completion(.failure(invalidResponseError))
            }
        }
    }

    /// Handles the result from the scan function
    private func handleScanResult(_ result: Result<[String: Any], Error>) {
        isProcessing = false

        switch result {
        case .success(let data):
            displayScanResult(data)
        case .failure(let error):
            displayScanError(error)
        }
    }

    /// Displays scan result to the user
    private func displayScanResult(_ data: [String: Any]) {
        print("🔍 [SCANNER DEBUG] ✅ Response received: \(data)")

        let success = data["success"] as? Bool ?? false
        let message = data["message"] as? String ?? ""
        let ticketStatus = data["ticketStatus"] as? String ?? ""

        print("🔍 [SCANNER DEBUG] Success: \(success)")
        print("🔍 [SCANNER DEBUG] Message: \(message)")
        print("🔍 [SCANNER DEBUG] Ticket Status: \(ticketStatus)")

        if success {
            successMessage = message
            showingSuccess = true
            triggerSuccessHaptic()
        } else if ticketStatus == "used" {
            displayAlreadyUsedTicket(data)
        } else {
            errorMessage = message
            showingError = true
            triggerErrorHaptic()
        }
    }

    /// Displays already-used ticket details
    private func displayAlreadyUsedTicket(_ data: [String: Any]) {
        if let ticketData = data["ticket"] as? [String: Any],
           let scannedAt = data["usedAt"] as? String,
           let scannedByName = data["scannedByName"] as? String {

            let eventName = ticketData["eventName"] as? String ?? "Unknown Event"
            let userName = ticketData["userName"] as? String ?? "Unknown"
            let ticketNumber = ticketData["ticketNumber"] as? String ?? "N/A"
            let scannedByEmail = data["scannedByEmail"] as? String
            let formattedTime = formatScanTime(scannedAt)

            alreadyUsedDetails = AlreadyUsedTicket(
                ticketNumber: ticketNumber,
                eventName: eventName,
                userName: userName,
                scannedAt: formattedTime,
                scannedBy: scannedByName,
                scannedByEmail: scannedByEmail
            )
            showingAlreadyUsed = true
            triggerErrorHaptic()
        } else {
            errorMessage = data["message"] as? String ?? "Ticket already used"
            showingError = true
        }
    }

    /// Displays scan error with user-friendly messaging
    private func displayScanError(_ error: Error) {
        let nsError = error as NSError
        print("🔍 [SCANNER DEBUG] ❌ ERROR RECEIVED")
        print("🔍 [SCANNER DEBUG] Error code: \(nsError.code)")
        print("🔍 [SCANNER DEBUG] Error domain: \(nsError.domain)")
        print("🔍 [SCANNER DEBUG] Error description: \(nsError.localizedDescription)")
        print("🔍 [SCANNER DEBUG] Error userInfo: \(nsError.userInfo)")

        var errorMsg = nsError.localizedDescription

        // Map common error messages to user-friendly versions
        if errorMsg.contains("not-found") || errorMsg.contains("Ticket not found") {
            errorMsg = "Ticket not found. Please check the ticket ID and try again."
        } else if errorMsg.contains("wrong-event") || errorMsg.contains("different event") {
            errorMsg = "This ticket is for a different event."
        } else if errorMsg.contains("permission-denied") || errorMsg.contains("Scanner role required") {
            errorMsg = "You don't have permission to scan tickets at this venue."
        } else if errorMsg.contains("invalid-argument") {
            errorMsg = "Invalid ticket format. Please check and try again."
        }

        print("🔍 [SCANNER DEBUG] Displaying error to user: \(errorMsg)")
        self.errorMessage = errorMsg
        self.showingError = true
    }

    // MARK: - Utilities
    private func formatScanTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func triggerErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
