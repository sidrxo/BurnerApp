import SwiftUI
import CodeScanner
import FirebaseFirestore
import FirebaseAuth
import AVFoundation

struct ScannerView: View {
    @State private var scannedValue: String = ""
    @State private var isShowingScanner = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var isProcessing = false
    @State private var userRole: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            if !canScanTickets {
                // Unauthorized access view
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.appLargeIcon)
                        .foregroundColor(.red)
                    
                    Text("Access Denied")
                        .appSectionHeader()
                        .foregroundColor(.white)
                    
                    Text("You don't have permission to scan tickets. Please contact an administrator if you need scanner access.")
                        .appBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Go Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .appBody()
                    .foregroundColor(.black)
                    .frame(maxWidth: 150)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else if !scannedValue.isEmpty {
                // Results Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scan Result")
                        .appSectionHeader()
                        .foregroundColor(.white)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("QR Code Data:")
                                .appBody()
                                .foregroundColor(.gray)
                            
                            Text(scannedValue)
                                .appBody()
                                .foregroundColor(.white)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxHeight: 200)
                    
                    HStack(spacing: 12) {
                        Button("Scan Again") {
                            resetScanner()
                        }
                        .appBody()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Process Ticket") {
                            processTicketScan()
                        }
                        .appBody()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .disabled(isProcessing)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // Scanner Instructions and Button
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.appLargeIcon)
                            .foregroundColor(.white)
                        
                        Text("QR Code Scanner")
                            .appSectionHeader()
                            .foregroundColor(.white)
                        
                        Text("Scan ticket QR codes to mark them as used")
                            .appBody()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Start Scanning") {
                        isShowingScanner = true
                    }
                    .appSectionHeader()
                    .foregroundColor(.black)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                }
            }
            
            if isProcessing {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                    Text("Processing ticket...")
                        .appBody()
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchUserRole()
        }
        .sheet(isPresented: $isShowingScanner) {
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
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isShowingScanner = false
                    }
                    .foregroundColor(.white)
                )
                .background(Color.black)
            }
        }
        .alert("Scanning Error", isPresented: $showingError) {
            Button("OK") { }
            Button("Try Again") {
                isShowingScanner = true
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("Scan Another") {
                resetScanner()
            }
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }
    
    private var canScanTickets: Bool {
        return userRole == "scanner" || userRole == "siteAdmin" || userRole == "venueAdmin" || userRole == "subAdmin"
    }
    
    private func fetchUserRole() {
        guard let userId = Auth.auth().currentUser?.uid else {
            userRole = ""
            return
        }
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data(),
                   let role = data["role"] as? String {
                    userRole = role
                } else {
                    userRole = "user"
                }
            }
        }
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            scannedValue = result.string
            if isTicketQRCode(result.string) {
                processTicketScan()
            }
        case .failure(let error):
            errorMessage = "Scanning failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func isTicketQRCode(_ qrData: String) -> Bool {
        if let _ = try? JSONSerialization.jsonObject(with: Data(qrData.utf8)) {
            return qrData.contains("EVENT_TICKET") || qrData.contains("ticketId")
        }
        return qrData.contains("TICKET:") && qrData.contains("EVENT:")
    }
    
    private func processTicketScan() {
        guard !scannedValue.isEmpty else { return }
        guard canScanTickets else {
            errorMessage = "You don't have permission to scan tickets"
            showingError = true
            return
        }
        
        isProcessing = true
        
        if let ticketData = parseQRCode(scannedValue) {
            markTicketAsUsed(ticketData: ticketData)
        } else {
            isProcessing = false
            errorMessage = "Invalid ticket QR code format"
            showingError = true
        }
    }
    
    private func parseQRCode(_ qrData: String) -> TicketQRData? {
        // Try parsing as JSON first
        if let data = qrData.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            guard let ticketId = json["ticketId"] as? String,
                  let eventId = json["eventId"] as? String else {
                return nil
            }
            
            return TicketQRData(
                ticketId: ticketId,
                eventId: eventId,
                userId: json["userId"] as? String,
                ticketNumber: json["ticketNumber"] as? String
            )
        }
        
        // Fallback to legacy format
        let components = qrData.components(separatedBy: ":")
        guard components.count >= 6,
              components[0] == "TICKET",
              components[2] == "EVENT",
              components[4] == "USER",
              let ticketIdIndex = components.firstIndex(of: "TICKET"),
              let eventIdIndex = components.firstIndex(of: "EVENT"),
              let userIdIndex = components.firstIndex(of: "USER") else {
            return nil
        }
        
        let ticketId = components[ticketIdIndex + 1]
        let eventId = components[eventIdIndex + 1]
        let userId = components[userIdIndex + 1]
        
        var ticketNumber: String?
        if let numberIndex = components.firstIndex(of: "NUMBER"), numberIndex + 1 < components.count {
            ticketNumber = components[numberIndex + 1]
        }
        
        return TicketQRData(
            ticketId: ticketId,
            eventId: eventId,
            userId: userId,
            ticketNumber: ticketNumber
        )
    }
    
    private func markTicketAsUsed(ticketData: TicketQRData) {
        let ticketRef = db.collection("tickets").document(ticketData.ticketId)
        
        // ✅ UPDATED: Add usedAt timestamp for Burner Mode monitoring
        let updateData: [String: Any] = [
            "status": "used",
            "usedAt": Timestamp(),
            "scannedBy": Auth.auth().currentUser?.uid ?? "unknown"
        ]
        
        ticketRef.updateData(updateData) { error in
            DispatchQueue.main.async {
                isProcessing = false
                
                if let error = error {
                    errorMessage = "Failed to update ticket: \(error.localizedDescription)"
                    showingError = true
                } else {
                    // Also update in user's subcollection
                    if let userId = ticketData.userId {
                        let userTicketRef = db.collection("users")
                            .document(userId)
                            .collection("tickets")
                            .document(ticketData.ticketId)
                        userTicketRef.updateData(updateData)
                    }
                    
                    successMessage = "Ticket successfully marked as used!\n\nTicket: \(ticketData.ticketNumber ?? ticketData.ticketId)\n\n🔥 Burner Mode will auto-enable for this user."
                    showingSuccess = true
                }
            }
        }
    }
    
    private func resetScanner() {
        scannedValue = ""
        isShowingScanner = true
    }
}

// MARK: - Supporting Types
struct TicketQRData {
    let ticketId: String
    let eventId: String
    let userId: String?
    let ticketNumber: String?
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
