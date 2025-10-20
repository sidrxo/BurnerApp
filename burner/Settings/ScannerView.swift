import SwiftUI
import CodeScanner
import FirebaseFirestore
import FirebaseAuth
internal import AVFoundation

struct ScannerView: View {
    @State private var scannedValue: String = ""
    @State private var isShowingScanner = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var isProcessing = false
    @State private var userRole: String = ""
    @State private var manualTicketNumber: String = ""
    
    @Environment(\.presentationMode) var presentationMode
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !canScanTickets {
                accessDeniedView
            } else {
                mainScannerView
            }
        }
        .onAppear { fetchUserRole() }
        .sheet(isPresented: $isShowingScanner) {
            scannerSheet
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(successMessage)
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
                        
                        VStack(spacing: 8) {
                            Text("QR Code Scanner")
                                .appBody()
                                .foregroundColor(.white)
                            
                            Text("Scan a ticket QR code to verify entry")
                                .appSecondary()
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
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
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("OR")
                            .appCaption()
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    
                    // Manual entry section
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
        ["scanner", "siteAdmin", "venueAdmin", "subAdmin"].contains(userRole)
    }
    
    // MARK: - Helper Functions
    private func fetchUserRole() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).getDocument { snapshot, _ in
            if let role = snapshot?.data()?["role"] as? String {
                userRole = role
            } else {
                userRole = "user"
            }
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            scannedValue = result.string
            processTicket(ticketId: extractTicketId(from: scannedValue))
        case .failure(let error):
            errorMessage = "Scanning failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func processManualTicket() {
        processTicket(ticketId: manualTicketNumber.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func extractTicketId(from qrData: String) -> String {
        // JSON format
        if let data = qrData.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ticketId = json["ticketId"] as? String {
            return ticketId
        }
        // Legacy format
        let components = qrData.components(separatedBy: ":")
        if let ticketIdIndex = components.firstIndex(of: "TICKET"), ticketIdIndex + 1 < components.count {
            return components[ticketIdIndex + 1]
        }
        return qrData // fallback to entire string
    }
    
    private func processTicket(ticketId: String) {
        guard !ticketId.isEmpty else { return }
        isProcessing = true
        
        let ticketRef = db.collection("tickets").document(ticketId)
        ticketRef.getDocument { snapshot, error in
            DispatchQueue.main.async {
                isProcessing = false
                
                if let error = error {
                    errorMessage = "Failed to fetch ticket: \(error.localizedDescription)"
                    showingError = true
                    return
                }
                
                guard let data = snapshot?.data() else {
                    errorMessage = "Ticket not found."
                    showingError = true
                    return
                }
                
                if let status = data["status"] as? String, status == "used" {
                    errorMessage = "This ticket has already been used."
                    showingError = true
                    return
                }
                
                // Mark ticket as used
                let updateData: [String: Any] = [
                    "status": "used",
                    "usedAt": Timestamp(date: Date()),
                    "scannedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ]
                
                ticketRef.updateData(updateData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            errorMessage = "Failed to update ticket: \(error.localizedDescription)"
                            showingError = true
                        } else {
                            successMessage = "Ticket successfully verified!"
                            showingSuccess = true
                            manualTicketNumber = ""
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScannerView()
        .preferredColorScheme(.dark)
}
