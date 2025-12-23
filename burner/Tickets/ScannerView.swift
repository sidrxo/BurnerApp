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
    @State private var manualTicketNumber: String = ""
    @State private var showManualEntry = false
    @State private var isCheckingScanner = true
    @State private var selectedEvent: Event?
    @State private var todaysEvents: [Event] = []
    @State private var isLoadingEvents = false
    @State private var isScanning = true

    @Environment(\.presentationMode) var presentationMode
    
    private var client: SupabaseClient {
        return SupabaseManager.shared.client
    }
    
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

                    Scanned: \(details.scannedAt)
                    By: \(details.scannedBy)
                    \(details.scannedByEmail != nil ? "()" : "")
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
                                validateAndScanTicket(ticketNumber: manualTicketNumber)
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
            checkScannerAccessFromClaims()
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
        return appStateUserRole == "scanner" || appStateUserRole == "venueAdmin" || appStateUserRole == "siteAdmin"
    }
    
    private func checkScannerAccessFromClaims() {
        guard client.auth.currentUser != nil else {
            DispatchQueue.main.async {
                self.isCheckingScanner = false
            }
            return
        }
        
        Task {
            _ = try? await client.auth.session
            
            await MainActor.run {
                self.isCheckingScanner = false
            }
        }
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
    
    
    private func validateAndScanTicket(qrCodeData: String? = nil, ticketNumber: String? = nil) {
        guard !isProcessing else { return }
        
        guard let selectedEvent = selectedEvent, let eventId = selectedEvent.id else {
            errorMessage = "Please select an event first"
            showingError = true
            self.isScanning = true
            return
        }

        var data: [String: String] = [:]

        if let qrData = qrCodeData, let ticketId = extractTicketId(from: qrData) {
            // QR scan - send UUID only
            data["ticket_id"] = ticketId
        } else if let ticketNum = ticketNumber, !ticketNum.isEmpty {
            // Manual entry - send ticket number + event ID for context
            data["ticket_number"] = ticketNum
            data["event_id"] = eventId
        } else {
            errorMessage = "Invalid QR Code or Ticket Number"
            showingError = true
            self.isScanning = false
            return
        }

        guard !data.isEmpty else {
            errorMessage = "No valid ticket identifier found"
            showingError = true
            self.isScanning = false
            return
        }

        isProcessing = true
        self.isScanning = false

        Task {
            do {
                
                // Use the Supabase client's built-in JSON decoding
                struct ScanResponse: Decodable {
                    let success: Bool
                    let message: String
                    let errorType: String?
                    let ticketNumber: String?
                    let userName: String?
                    let eventName: String?
                    let scannedBy: String?
                    let scannedByEmail: String?
                    let scannedAt: String?
                    let actualEvent: String?
                    
                    enum CodingKeys: String, CodingKey {
                        case success, message, errorType
                        case ticketNumber, userName, eventName
                        case scannedBy, scannedByEmail, scannedAt
                        case actualEvent
                    }
                }
                
                let response: ScanResponse = try await client.functions.invoke(
                    "scan-ticket",
                    options: FunctionInvokeOptions(body: data)
                )
                

                await MainActor.run {
                    self.isProcessing = false
                    self.manualTicketNumber = ""
                    
                    if response.success {
                        self.successMessage = response.message
                        self.showingSuccess = true
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } else {
                        // Handle different error types
                        switch response.errorType {
                        case "ALREADY_USED":
                            // Show detailed already-used alert
                            if let scannedBy = response.scannedBy,
                               let scannedAt = response.scannedAt {
                                
                                let userName = response.userName ?? "Guest"
                                let ticketNum = response.ticketNumber ?? "Unknown"
                                let eventName = response.eventName ?? selectedEvent.name
                                let formattedTime = self.formatScanTime(scannedAt)
                                
                                self.alreadyUsedDetails = AlreadyUsedTicket(
                                    ticketNumber: ticketNum,
                                    eventName: eventName,
                                    userName: userName,
                                    scannedAt: formattedTime,
                                    scannedBy: scannedBy,
                                    scannedByEmail: response.scannedByEmail
                                )
                                self.showingAlreadyUsed = true
                            } else {
                                self.errorMessage = response.message
                                self.showingError = true
                            }
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            
                        case "WRONG_EVENT":
                            if let actualEvent = response.actualEvent {
                                self.errorMessage = "This ticket is for '\(actualEvent)', not this event."
                            } else {
                                self.errorMessage = response.message
                            }
                            self.showingError = true
                            
                        case "CANCELLED":
                            self.errorMessage = "This ticket has been cancelled and cannot be used."
                            self.showingError = true
                            
                        case "PERMISSION_DENIED":
                            self.errorMessage = "You don't have permission to scan tickets at this venue."
                            self.showingError = true
                            
                        case "TICKET_NOT_FOUND":
                            self.errorMessage = "Ticket not found. Please check the ticket and try again."
                            self.showingError = true
                            
                        case "UNAUTHENTICATED":
                            self.errorMessage = "Please sign in to scan tickets."
                            self.showingError = true
                            
                        case "INVALID_STATUS":
                            self.errorMessage = "This ticket has an invalid status and cannot be scanned."
                            self.showingError = true
                            
                        default:
                            // Fallback to generic message
                            self.errorMessage = response.message
                            self.showingError = true
                        }
                        
                        // Haptic feedback for errors (except already-used which is handled above)
                        if response.errorType != "ALREADY_USED" {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleScanError(error: error)
                }
            }
        }
    }

    private func handleAlreadyUsedTicket(jsonData: [String: Any]) {
        if let scannedBy = jsonData["scannedBy"] as? String,
           let scannedAt = jsonData["scannedAt"] as? String {
            
            let scannedByEmail = jsonData["scannedByEmail"] as? String
            let userName = jsonData["userName"] as? String ?? "Guest"
            let ticketNum = jsonData["ticketNumber"] as? String ?? "Unknown"
            let eventName = selectedEvent?.name ?? "Unknown Event"
            
            let formattedTime = self.formatScanTime(scannedAt)
            
            self.alreadyUsedDetails = AlreadyUsedTicket(
                ticketNumber: ticketNum,
                eventName: eventName,
                userName: userName,
                scannedAt: formattedTime,
                scannedBy: scannedBy,
                scannedByEmail: scannedByEmail
            )
            self.showingAlreadyUsed = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        } else {
            self.errorMessage = "Ticket already used"
            self.showingError = true
        }
    }

    private func handleScanError(error: Error) {
        self.isProcessing = false
        self.manualTicketNumber = ""
        self.isScanning = false
        
        let errorMsg = error.localizedDescription
        
        if errorMsg.contains("Ticket not found") {
            self.errorMessage = "Ticket not found. Please check the ticket and try again."
        } else if errorMsg.contains("Permission denied") {
            self.errorMessage = "You don't have permission to scan tickets at this venue."
        } else if errorMsg.contains("Invalid parameters") {
            self.errorMessage = "Invalid ticket format. Please try again."
        } else if errorMsg.contains("Event is sold out") {
            self.errorMessage = "This event is sold out."
        } else if errorMsg.contains("Unauthenticated") {
            self.errorMessage = "Please sign in to scan tickets."
        } else {
            self.errorMessage = "Scan failed: \(errorMsg)"
        }
        
        self.showingError = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // UPDATED: Enhanced QR code extraction with better debugging
    private func extractTicketId(from qrData: String) -> String? {
        
        // First, try to parse as JSON directly
        if let data = qrData.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let type = json["type"] as? String, type == "EVENT_TICKET" {
            
            // Return ticket_id (UUID) from QR code
            if let ticketId = json["ticket_id"] as? String {
                return ticketId
            } else if let ticketId = json["ticketId"] as? String {
                return ticketId
            }
        }
        
        // If direct parsing fails, try unescaping first (for double-encoded JSON)
        let unescaped = qrData
            .replacingOccurrences(of: "\\\"", with: "\"")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        if unescaped != qrData {
            if let data = unescaped.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let type = json["type"] as? String, type == "EVENT_TICKET" {
                
                if let ticketId = json["ticket_id"] as? String {
                    return ticketId
                } else if let ticketId = json["ticketId"] as? String {
                    return ticketId
                }
            }
        }
        
        // Check if it's already a UUID (contains hyphens and proper length)
        if qrData.contains("-") && qrData.count == 36 {
            print("✅ Direct UUID detected: \(qrData)")
            return qrData
        }
        
        return nil
    }
    
    private func fetchTodaysEvents() {
        isLoadingEvents = true

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        Task {
            do {
                let events: [Event] = try await client
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
