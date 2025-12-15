import SwiftUI
import CodeScanner
import AVFoundation
import Supabase

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
    // REMOVED: @State private var userRole: String = "" // Now using appState.userRole
    @State private var manualTicketNumber: String = ""
    @State private var showManualEntry = false
    // REMOVED: @State private var isScannerActive = false
    @State private var isCheckingScanner = true // Keep this to prevent UI flash
    @State private var selectedEvent: Event?
    @State private var todaysEvents: [Event] = []
    @State private var isLoadingEvents = false
    @State private var isScanning = true

    @Environment(\.presentationMode) var presentationMode
    
    private var client: SupabaseClient {
        return SupabaseManager.shared.client
    }
    
    // NEW: Computed property for the role
    private var appStateUserRole: String {
        return appState.userRole
    }
    
    private let selectedEventIdKey = "selectedScannerEventId"
    
    struct AlreadyUsedTicket: Decodable {
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
                    primaryAction: {
                        showingError = false
                        self.isScanning = true
                    },
                    primaryActionTitle: "TRY AGAIN",
                    primaryActionColor: .red,
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }

            if showingSuccess {
                CustomAlertView(
                    title: "Success",
                    description: successMessage,
                    primaryAction: {
                        showingSuccess = false
                        self.isScanning = true
                    },
                    primaryActionTitle: "SCAN NEXT",
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
                    primaryAction: {
                        showingAlreadyUsed = false
                        self.isScanning = true
                    },
                    primaryActionTitle: "SCAN NEXT",
                    primaryActionColor: .orange,
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
                            self.isScanning = true
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
            // REMOVED: fetchUserRoleFromClaims()
            checkScannerAccessFromClaims() // Remains, but only flags loading finished
            fetchTodaysEvents()
            loadPersistedEventSelection()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showManualEntry)
    }
    
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
    
    private var accessDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .appHero()
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
                
                Text("Role: \(appStateUserRole.isEmpty ? "not loaded" : appStateUserRole)")
                    .appSecondary()
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 8)
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
                    .padding(.bottom, 20)
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
    
    private var scannerViewFinder: some View {
        ZStack {
            if isScanning {
                CodeScannerView(
                    codeTypes: [.qr],
                    showViewfinder: true,
                    simulatedData: "TEST_TICKET_123",
                    completion: handleScan
                )
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack {
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            self.isScanning = false
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
    
    private func loadPersistedEventSelection() {
        guard let eventId = UserDefaults.standard.string(forKey: selectedEventIdKey) else { return }
        
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
        // FIXED: Use appStateUserRole for immediate role check
        return appStateUserRole == "scanner" || appStateUserRole == "venueAdmin" || appStateUserRole == "siteAdmin"
    }
    
    private func checkScannerAccessFromClaims() {
        guard client.auth.currentUser != nil else {
            DispatchQueue.main.async {
                self.isCheckingScanner = false
            }
            return
        }
        
        // This task now only waits for the session to ensure the AppState has loaded claims.
        // It does not locally fetch or set the role.
        Task {
            // Attempt to get session (which triggers claim fetch/refresh)
            _ = try? await client.auth.session
            
            await MainActor.run {
                self.isCheckingScanner = false // Signal loading is complete
            }
        }
    }

    private func fetchUserRoleFromClaims() {
        // REMOVED: This function is now redundant as AppState should manage the role
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        self.isScanning = false

        switch result {
        case .success(let scanResult):
            validateAndScanTicket(qrCodeData: scanResult.string)
            
        case .failure(let error):
            errorMessage = "Scanning failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func extractTicketId(from qrData: String) -> String? {
        if let url = URL(string: qrData),
            (url.host == "partypass.com" || url.host == "www.partypass.com"),
            url.pathComponents.contains("ticket") {
            
            if let ticketId = url.pathComponents.last, ticketId.count > 10 {
                return ticketId
            }
        }
        
        if let data = qrData.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let type = json["type"] as? String, type == "EVENT_TICKET",
            let ticketId = json["ticketId"] as? String {
            
            return ticketId
        }
        
        return nil
    }
    
    private func validateAndScanTicket(qrCodeData: String? = nil, ticketId: String? = nil) {
        guard !isProcessing else { return }
        
        guard let selectedEvent = selectedEvent, let eventId = selectedEvent.id else {
            errorMessage = "Please select an event first"
            showingError = true
            self.isScanning = true
            return
        }

        var finalTicketId: String = ""
        var isTicketNumber: Bool = false

        if let id = ticketId {
            finalTicketId = id
            if id.starts(with: "TKT") && id.count > 10 {
                isTicketNumber = true
            }
        } else if let qrData = qrCodeData, let extracted = extractTicketId(from: qrData) {
            finalTicketId = extracted
        } else {
            errorMessage = "Invalid QR Code or Ticket ID"
            showingError = true
            self.isScanning = false
            return
        }

        guard !finalTicketId.isEmpty else {
            errorMessage = "Invalid ticket ID"
            showingError = true
            self.isScanning = false
            return
        }

        isProcessing = true
        self.isScanning = false

        // FIX: Define dictionary strictly as [String: String] to satisfy Encodable
        var data: [String: String] = [
            "eventId": eventId
        ]
        
        if let qrData = qrCodeData {
            data["qrCodeData"] = qrData
        }
        
        if isTicketNumber {
            data["ticketNumber"] = finalTicketId
        } else {
            data["ticketId"] = finalTicketId
        }

        Task {
            do {
                // FIX: Use unlabeled first argument for name, and 'options:' for the body
                // Return Data explicitly to allow manual JSON parsing
                let responseData: Data = try await client.functions.invoke(
                    "scan-ticket",
                    options: FunctionInvokeOptions(
                        body: data
                    )
                )
                
                // Manually parse the JSON response from Data
                guard let data = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                    throw NSError(domain: "SupabaseFunction", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid function response format"])
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.manualTicketNumber = ""
                    
                    let success = data["success"] as? Bool ?? false
                    let message = data["message"] as? String ?? ""
                    let ticketStatus = data["ticketStatus"] as? String ?? ""

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
                            self.errorMessage = "Ticket used, but details missing."
                            self.showingError = true
                        }
                    } else {
                        self.errorMessage = message
                        self.showingError = true
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.manualTicketNumber = ""
                    self.isScanning = false
                    
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("Ticket not found") {
                        self.errorMessage = "Ticket not found. Please check the ticket ID and try again."
                    } else if errorMsg.contains("Permission denied") {
                        self.errorMessage = "You don't have permission to scan tickets at this venue."
                    } else {
                        self.errorMessage = "Validation failed: \(errorMsg)"
                    }
                    self.showingError = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func fetchTodaysEvents() {
        isLoadingEvents = true

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        Task {
            do {
                let events: [Event] = try await client.database
                    .from("events")
                    .select()
                    .eq("status", value: "active")
                    .gte("start_time", value: today.ISO8601Format())
                    .lt("start_time", value: tomorrow.ISO8601Format())
                    .order("start_time", ascending: true)
                    .execute()
                    .value

                await MainActor.run {
                    self.isLoadingEvents = false
                    self.todaysEvents = events
                    self.loadPersistedEventSelection()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingEvents = false
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
}
