import SwiftUI
import CodeScanner
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import AVFoundation

struct ScannerView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var scannedValue: String = ""
    @State private var isShowingScanner = false
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

    @Environment(\.presentationMode) var presentationMode
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
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
            } else {
                mainScannerView
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
        }
        .onAppear {
            print("🟢 [Scanner] View appeared")
            fetchUserRoleFromClaims()
            checkScannerAccessFromClaims()
        }
        .sheet(isPresented: $isShowingScanner) {
            scannerSheet
        }
    }
    
    // MARK: - Access Denied View
    private var accessDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.appLargeIcon)
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

            Button("Go Back") {
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
    
    // MARK: - Main Scanner View
    private var mainScannerView: some View {
        VStack(spacing: 0) {
            SettingsHeaderSection(title: "Scanner")
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Scanner icon and description
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.appLargeIcon)
                            .foregroundColor(.white)
                            .padding(.top, 40)

                        VStack(spacing: 8) {
                            Text("QR Code Scanner")
                                .appSectionHeader()
                                .foregroundColor(.white)

                            Text("Scan a ticket")
                                .appBody()
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Scan button
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera")
                                .font(.appIcon)
                            
                            Text("Start Scanning")
                                .appBody()
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    
                    // Toggle for manual entry
                    Button(action: {
                        withAnimation {
                            showManualEntry.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: showManualEntry ? "chevron.up" : "chevron.down")
                                .font(.appCaption)
                            
                            Text(showManualEntry ? "Hide Manual Entry" : "Manual Entry")
                                .appBody()
                        }
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Manual entry section - collapsible
                    if showManualEntry {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Manual Entry")
                                    .appBody()
                                    .foregroundColor(.white)
                                
                                Text("Enter ticket number manually")
                                    .appSecondary()
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Ticket Number", text: $manualTicketNumber)
                                .appBody()
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                            
                            Button(action: {
                                processManualTicket()
                            }) {
                                HStack(spacing: 8) {
                                    if isProcessing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.black)
                                    }
                                    
                                    Text(isProcessing ? "Processing..." : "Verify Ticket")
                                        .appBody()
                                }
                                .foregroundColor(canProcessTicket ? .black : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canProcessTicket ? Color.white : Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(!canProcessTicket)
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Scanner Sheet
    private var scannerSheet: some View {
        NavigationView {
            CodeScannerView(
                codeTypes: [.qr],
                scanMode: .once,
                manualSelect: false,
                showViewfinder: true,
                completion: handleScan
            )
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isShowingScanner = false
                    }
                    .appBody()
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canProcessTicket: Bool {
        !isProcessing && !manualTicketNumber.isEmpty
    }

    private var canScanTickets: Bool {
        let hasValidRole = ["scanner", "siteAdmin", "venueAdmin", "subAdmin"].contains(userRole)
        let canScan = hasValidRole && (isScannerActive || userRole != "scanner")
        
        print("🔍 [Scanner] Access Check:")
        print("   • User Role: \(userRole)")
        print("   • Has Valid Role: \(hasValidRole)")
        print("   • Scanner Active: \(isScannerActive)")
        print("   • Can Scan: \(canScan)")
        
        return canScan
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading scanner...")
                .appBody()
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Helper Functions (Using Custom Claims)
    
    private func fetchUserRoleFromClaims() {
        guard Auth.auth().currentUser != nil else {
            print("🔴 [Scanner] No user signed in")
            return
        }
        
        print("🔵 [Scanner] Fetching role from custom claims")
        
        Task {
            do {
                if let role = try await appState.authService.getUserRole() {
                    await MainActor.run {
                        self.userRole = role
                        print("✅ [Scanner] User role from custom claims: \(role)")
                    }
                } else {
                    await MainActor.run {
                        self.userRole = "user"
                        print("⚠️ [Scanner] No role in custom claims, defaulting to 'user'")
                    }
                }
            } catch {
                print("🔴 [Scanner] Error fetching custom claims: \(error.localizedDescription)")
                await MainActor.run {
                    self.userRole = "user"
                }
            }
        }
    }

    private func checkScannerAccessFromClaims() {
        guard Auth.auth().currentUser != nil else {
            print("🔴 [Scanner] No user for scanner access check")
            isCheckingScanner = false
            return
        }

        print("🔵 [Scanner] Checking scanner access from custom claims")
        
        Task {
            do {
                let active = try await appState.authService.isScannerActive()
                await MainActor.run {
                    self.isScannerActive = active
                    self.isCheckingScanner = false
                    print("✅ [Scanner] Scanner active from custom claims: \(active)")
                }
            } catch {
                print("🔴 [Scanner] Error checking scanner access: \(error.localizedDescription)")
                await MainActor.run {
                    self.isScannerActive = false
                    self.isCheckingScanner = false
                }
            }
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            print("🔵 [Scanner] QR Code scanned: \(result.string)")
            scannedValue = result.string
            processTicket(qrCodeData: scannedValue)
        case .failure(let error):
            print("🔴 [Scanner] Scan failed: \(error.localizedDescription)")
            errorMessage = "Scanning failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func processManualTicket() {
        let ticketId = manualTicketNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔵 [Scanner] Processing manual ticket: \(ticketId)")
        processTicket(qrCodeData: nil, ticketId: ticketId)
    }
    
    private func extractTicketId(from qrData: String) -> String? {
        // JSON format
        if let data = qrData.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ticketId = json["ticketId"] as? String {
            print("🔵 [Scanner] Extracted ticketId from JSON: \(ticketId)")
            return ticketId
        }
        // Legacy format
        let components = qrData.components(separatedBy: ":")
        if let ticketIdIndex = components.firstIndex(of: "TICKET"), ticketIdIndex + 1 < components.count {
            let ticketId = components[ticketIdIndex + 1]
            print("🔵 [Scanner] Extracted ticketId from legacy format: \(ticketId)")
            return ticketId
        }
        print("⚠️ [Scanner] Could not extract ticketId, using raw QR data")
        return nil
    }
    
    private func processTicket(qrCodeData: String? = nil, ticketId: String? = nil) {
        guard !isProcessing else {
            print("⚠️ [Scanner] Already processing a ticket")
            return
        }
        
        let finalTicketId: String
        
        if let ticketId = ticketId {
            finalTicketId = ticketId
        } else if let qrData = qrCodeData, let extracted = extractTicketId(from: qrData) {
            finalTicketId = extracted
        } else if let qrData = qrCodeData {
            finalTicketId = qrData
        } else {
            print("🔴 [Scanner] Invalid ticket data")
            errorMessage = "Invalid ticket data"
            showingError = true
            return
        }
        
        guard !finalTicketId.isEmpty else {
            print("🔴 [Scanner] Empty ticket ID")
            errorMessage = "Invalid ticket ID"
            showingError = true
            return
        }
        
        print("🔵 [Scanner] Processing ticket with ID: \(finalTicketId)")
        print("🔵 [Scanner] Current user role: \(userRole)")
        print("🔵 [Scanner] Scanner active: \(isScannerActive)")
        
        isProcessing = true
        
        // Call Cloud Function
        let scanFunction = functions.httpsCallable("scanTicket")
        let data: [String: Any] = [
            "ticketId": finalTicketId,
            "qrCodeData": qrCodeData as Any
        ]
        
        print("🔵 [Scanner] Calling Cloud Function with data: \(data)")
        
        scanFunction.call(data) { result, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                self.manualTicketNumber = ""

                if let error = error as NSError? {
                    print("🔴 [Scanner] Cloud Function error:")
                    print("   • Error code: \(error.code)")
                    print("   • Error domain: \(error.domain)")
                    print("   • Error description: \(error.localizedDescription)")
                    print("   • User info: \(error.userInfo)")
                    
                    // Parse error message for better user feedback
                    var errorMsg = error.localizedDescription

                    // Check for specific error messages
                    if errorMsg.contains("not-found") || errorMsg.contains("Ticket not found") {
                        errorMsg = "Ticket not found. Please check the ticket ID and try again."
                    } else if errorMsg.contains("permission-denied") || errorMsg.contains("Scanner role required") {
                        errorMsg = "You don't have permission to scan tickets at this venue."
                    } else if errorMsg.contains("invalid-argument") {
                        errorMsg = "Invalid ticket format. Please check and try again."
                    }

                    self.errorMessage = errorMsg
                    self.showingError = true
                    return
                }
                
                guard let data = result?.data as? [String: Any] else {
                    print("🔴 [Scanner] Invalid response from Cloud Function")
                    self.errorMessage = "Invalid response from server"
                    self.showingError = true
                    return
                }
                
                print("✅ [Scanner] Cloud Function response: \(data)")
                
                let success = data["success"] as? Bool ?? false
                let message = data["message"] as? String ?? ""
                let ticketStatus = data["ticketStatus"] as? String ?? ""
                
                if success {
                    // Ticket successfully scanned
                    print("✅ [Scanner] Ticket scanned successfully")
                    self.successMessage = message
                    self.showingSuccess = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } else if ticketStatus == "used" {
                    // Ticket already used - show detailed alert
                    print("⚠️ [Scanner] Ticket already used")
                    if let ticketData = data["ticket"] as? [String: Any],
                       let scannedAt = data["usedAt"] as? String,
                       let scannedByName = data["scannedByName"] as? String {
                        
                        let eventName = ticketData["eventName"] as? String ?? "Unknown Event"
                        let userName = ticketData["userName"] as? String ?? "Unknown"
                        let ticketNumber = ticketData["ticketNumber"] as? String ?? "N/A"
                        let scannedByEmail = data["scannedByEmail"] as? String
                        
                        // Format the scanned time
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
                        
                        // Haptic feedback for error
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    } else {
                        self.errorMessage = message
                        self.showingError = true
                    }
                } else {
                    // Other error
                    print("🔴 [Scanner] Ticket scan failed: \(message)")
                    self.errorMessage = message
                    self.showingError = true
                    
                    // Haptic feedback
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
}

// MARK: - Preview
#Preview {
    ScannerView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
