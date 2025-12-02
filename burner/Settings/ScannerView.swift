import SwiftUI
import CodeScanner
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import AVFoundation

struct ScannerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    
    @State private var scannedValue: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var showingAlreadyUsed = false
    @State private var alreadyUsedDetails: AlreadyUsedTicket?
    @State private var isProcessing = false
    @State private var userRole: String = ""
    @State private var manualTicketNumber: String = ""
    @State private var showManualEntry = false
    @State private var isScannerActive = false
    @State private var isCheckingScanner = true
    @State private var selectedEvent: Event?
    @State private var todaysEvents: [Event] = []
    @State private var isLoadingEvents = false

    @Environment(\.presentationMode) var presentationMode
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west2")
    
    // UserDefaults key for persistent event selection
    private let selectedEventIdKey = "selectedScannerEventId"
    
    struct AlreadyUsedTicket {
        let ticketNumber: String
        let eventName: String
        let userName: String
        let scannedAt: String
        let scannedBy: String
        let scannedByEmail: String?
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isCheckingScanner {
                loadingView
            } else if !canScanTickets {
                accessDeniedView
            } else if selectedEvent == nil {
                eventSelectionView
            } else {
                scannerViewFinder
            }

            // Custom Alerts
            if showingError {
                CustomAlertView(
                    title: "Error",
                    description: errorMessage,
                    primaryAction: { showingError = false },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }

            if showingSuccess {
                CustomAlertView(
                    title: "Success",
                    description: successMessage,
                    primaryAction: { showingSuccess = false },
                    primaryActionTitle: "Done",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }

            if showingAlreadyUsed, let details = alreadyUsedDetails {
                CustomAlertView(
                    title: "Ticket Already Used",
                    description: """
                    This ticket was already scanned.

                    Event: \(details.eventName)
                    Ticket: \(details.ticketNumber)
                    Guest: \(details.userName)

                    Scanned: \(details.scannedAt)
                    By: \(details.scannedBy)
                    \(details.scannedByEmail != nil ? "(\(details.scannedByEmail!))" : "")
                    """,
                    primaryAction: { showingAlreadyUsed = false },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }
            
            // Manual Entry Sheet
            if showManualEntry {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showManualEntry = false
                        manualTicketNumber = ""
                    }
                
                VStack(spacing: 20) {
                    Text("Enter Ticket Number")
                        .appSectionHeader()
                        .foregroundColor(.white)
                    
                    TextField("Ticket Number", text: $manualTicketNumber)
                        .padding(12)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button("CANCEL") {
                            showManualEntry = false
                            manualTicketNumber = ""
                        }
                        .appBody()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button("SUBMIT") {
                            if !manualTicketNumber.isEmpty {
                                showManualEntry = false
                                validateAndScanTicket(ticketId: manualTicketNumber)
                            }
                        }
                        .appBody()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(manualTicketNumber.isEmpty)
                        .opacity(manualTicketNumber.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                }
                .padding(24)
                .background(Color(white: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            fetchUserRoleFromClaims()
            checkScannerAccessFromClaims()
            fetchTodaysEvents()
            loadPersistedEventSelection()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showManualEntry)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading...")
                .appBody()
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Access Denied View
    private var accessDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("Access Denied")
                    .appSectionHeader()
                    .foregroundColor(.white)

                Text("You don't have permission to scan tickets.")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Debug info
                Text("Role: \(userRole.isEmpty ? "not loaded" : userRole)")
                    .appSecondary()
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 8)
                
                Text("Scanner Active: \(isScannerActive ? "Yes" : "No")")
                    .appSecondary()
                    .foregroundColor(.gray.opacity(0.6))
            }

            Button("GO BACK") {
                presentationMode.wrappedValue.dismiss()
            }
            .appBody()
            .foregroundColor(.black)
            .frame(maxWidth: 200)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Event Selection View
    private var eventSelectionView: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "Select Event", includeTopPadding: false, includeHorizontalPadding: false)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            if isLoadingEvents {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    Text("Loading events...")
                        .appBody()
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if todaysEvents.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding(.top, 60)

                    VStack(spacing: 8) {
                        Text("No Events Today")
                            .appSectionHeader()
                            .foregroundColor(.white)

                        Text("There are no events scheduled for today")
                            .appBody()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(todaysEvents, id: \.id) { event in
                            Button(action: {
                                selectEvent(event)
                            }) {
                                EventRow(
                                    event: event,
                                    bookmarkManager: nil,
                                    configuration: .eventList
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Scanner ViewFinder
    private var scannerViewFinder: some View {
        ZStack {
            // Camera ViewFinder
            CodeScannerView(
                codeTypes: [.qr],
                scanMode: .once,
                showViewfinder: true,
                simulatedData: "TEST_TICKET_123",
                completion: handleScan
            )
            .ignoresSafeArea()
            
            // Overlay with manual entry and event info
            VStack {
                // Top section with manual entry pill
                VStack(spacing: 16) {
                    // Manual Entry Pill
                    Button(action: {
                        withAnimation {
                            showManualEntry = true
                        }
                    }) {
                        Text("MANUAL ENTRY")
                            .appBody()
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 60)
                }
                
                Spacer()
                
                // Event info card below viewfinder
                if let selectedEvent = selectedEvent {
                    VStack(spacing: 8) {
                        Text(selectedEvent.name)
                            .appBody()
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        
                        Text(selectedEvent.venue)
                            .appSecondary()
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            clearEventSelection()
                        }) {
                            Text("CHANGE EVENT")
                                .appSecondary()
                                .foregroundColor(.white.opacity(0.6))
                                .underline()
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                
                // Processing indicator
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Processing...")
                            .appBody()
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func loadPersistedEventSelection() {
        guard let eventId = UserDefaults.standard.string(forKey: selectedEventIdKey) else { return }
        
        // Find the event in today's events once they're loaded
        if let event = todaysEvents.first(where: { $0.id == eventId }) {
            selectedEvent = event
        }
    }
    
    private func selectEvent(_ event: Event) {
        selectedEvent = event
        if let eventId = event.id {
            UserDefaults.standard.set(eventId, forKey: selectedEventIdKey)
        }
    }
    
    private func clearEventSelection() {
        selectedEvent = nil
        UserDefaults.standard.removeObject(forKey: selectedEventIdKey)
    }
    
    private var canScanTickets: Bool {
        return userRole == "scanner" || userRole == "venueAdmin" || userRole == "siteAdmin"
    }
    
    private func checkScannerAccessFromClaims() {
        guard let user = Auth.auth().currentUser else {
            print("🔍 [SCANNER DEBUG] ❌ No user authenticated")
            DispatchQueue.main.async {
                self.isCheckingScanner = false
                self.isScannerActive = false
            }
            return
        }
        
        print("🔍 [SCANNER DEBUG] Checking scanner access for user: \(user.uid)")
        
        user.getIDTokenResult { result, error in
            DispatchQueue.main.async {
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
    
    private func fetchUserRoleFromClaims() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.getIDTokenResult { result, error in
            if let claims = result?.claims,
               let role = claims["role"] as? String {
                DispatchQueue.main.async {
                    self.userRole = role
                }
            }
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let scanResult):
            print("🔍 [SCANNER DEBUG] QR Code scanned: \(scanResult.string)")
            validateAndScanTicket(qrCodeData: scanResult.string)
            
        case .failure(let error):
            print("🔍 [SCANNER DEBUG] ❌ Scan failed: \(error.localizedDescription)")
            errorMessage = "Scanning failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
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
        
        print("🔍 [SCANNER DEBUG] ⚠️ Could not extract ticket ID, using raw data")
        return nil
    }
    
    private func validateAndScanTicket(qrCodeData: String? = nil, ticketId: String? = nil) {
        print("🔍 [SCANNER DEBUG] === SCAN INITIATED ===")
        print("🔍 [SCANNER DEBUG] QR Data: \(qrCodeData ?? "nil")")
        print("🔍 [SCANNER DEBUG] Manual Ticket ID: \(ticketId ?? "nil")")
        
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

        var finalTicketId: String = ""

        if let ticketId = ticketId {
            finalTicketId = ticketId
            print("🔍 [SCANNER DEBUG] Using manual ticket ID: \(finalTicketId)")
        } else if let qrData = qrCodeData, let extracted = extractTicketId(from: qrData) {
            finalTicketId = extracted
            print("🔍 [SCANNER DEBUG] Extracted ticket ID from QR: \(finalTicketId)")
        } else if let qrData = qrCodeData {
            finalTicketId = qrData
            print("🔍 [SCANNER DEBUG] Using raw QR data as ticket ID: \(finalTicketId)")
        } else {
            print("🔍 [SCANNER DEBUG] ❌ No valid ticket data provided")
            errorMessage = "Invalid ticket data"
            showingError = true
            return
        }

        guard !finalTicketId.isEmpty else {
            print("🔍 [SCANNER DEBUG] ❌ Final ticket ID is empty")
            errorMessage = "Invalid ticket ID"
            showingError = true
            return
        }

        print("🔍 [SCANNER DEBUG] Final Ticket ID: \(finalTicketId)")
        print("🔍 [SCANNER DEBUG] Selected Event ID: \(eventId)")

        isProcessing = true

        // Call Cloud Function with event verification
        let scanFunction = functions.httpsCallable("scanTicket")
        let data: [String: Any] = [
            "ticketId": finalTicketId,
            "eventId": eventId,
            "qrCodeData": qrCodeData as Any
        ]

        print("🔍 [SCANNER DEBUG] Calling cloud function with data: \(data)")

        scanFunction.call(data) { result, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                self.manualTicketNumber = ""

                if let error = error as NSError? {
                    print("🔍 [SCANNER DEBUG] ❌ ERROR RECEIVED")
                    print("🔍 [SCANNER DEBUG] Error code: \(error.code)")
                    print("🔍 [SCANNER DEBUG] Error domain: \(error.domain)")
                    print("🔍 [SCANNER DEBUG] Error description: \(error.localizedDescription)")
                    print("🔍 [SCANNER DEBUG] Error userInfo: \(error.userInfo)")

                    var errorMsg = error.localizedDescription

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
                    return
                }

                guard let data = result?.data as? [String: Any] else {
                    print("🔍 [SCANNER DEBUG] ❌ Invalid response format from server")
                    self.errorMessage = "Invalid response from server"
                    self.showingError = true
                    return
                }

                print("🔍 [SCANNER DEBUG] ✅ Response received: \(data)")

                let success = data["success"] as? Bool ?? false
                let message = data["message"] as? String ?? ""
                let ticketStatus = data["ticketStatus"] as? String ?? ""

                print("🔍 [SCANNER DEBUG] Success: \(success)")
                print("🔍 [SCANNER DEBUG] Message: \(message)")
                print("🔍 [SCANNER DEBUG] Ticket Status: \(ticketStatus)")

                if success {
                    self.successMessage = message
                    self.showingSuccess = true

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } else if ticketStatus == "used" {
                    if let ticketData = data["ticket"] as? [String: Any],
                       let scannedAt = data["usedAt"] as? String,
                       let scannedByName = data["scannedByName"] as? String {

                        let eventName = ticketData["eventName"] as? String ?? "Unknown Event"
                        let userName = ticketData["userName"] as? String ?? "Unknown"
                        let ticketNumber = ticketData["ticketNumber"] as? String ?? "N/A"
                        let scannedByEmail = data["scannedByEmail"] as? String

                        let formattedTime = self.formatScanTime(scannedAt)

                        self.alreadyUsedDetails = AlreadyUsedTicket(
                            ticketNumber: ticketNumber,
                            eventName: eventName,
                            userName: userName,
                            scannedAt: formattedTime,
                            scannedBy: scannedByName,
                            scannedByEmail: scannedByEmail
                        )
                        self.showingAlreadyUsed = true

                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    } else {
                        self.errorMessage = message
                        self.showingError = true
                    }
                } else {
                    self.errorMessage = message
                    self.showingError = true

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
    
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

    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func fetchTodaysEvents() {
        isLoadingEvents = true

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        print("🔍 [SCANNER DEBUG] Fetching events for today...")

        db.collection("events")
            .whereField("startTime", isGreaterThanOrEqualTo: today)
            .whereField("startTime", isLessThan: tomorrow)
            .whereField("status", isEqualTo: "active")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
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
}
