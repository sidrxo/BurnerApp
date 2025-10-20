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
        VStack(spacing: 20) {
            if !canScanTickets {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.appLargeIcon)
                        .foregroundColor(.white)

                    Text("Access Denied")
                        .appSectionHeader()
                        .foregroundColor(.white)

                    Text("You don't have permission to scan tickets.")
                        .appBody()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button("Go Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .appBody()
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 150)
                    .background(Color(.black).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.darkGray))
                
            } else {
                // Main scanner view
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.appLargeIcon)
                            .foregroundColor(.white)
                        
                        Text("QR Code Scanner")
                            .appSectionHeader()
                            .foregroundColor(.white)
                        
                        Text("Scan a ticket QR code or enter the ticket number manually")
                            .appBody()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Start Scanning") {
                        isShowingScanner = true
                    }
                    .appBody()
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 14)
                    .background(Color(.black).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Manual ticket entry
                    VStack(spacing: 12) {
                        TextField("Enter ticket number", text: $manualTicketNumber)
                            .padding(12)
                            .background(Color(.gray).opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .appBody()
                            .foregroundColor(.white)
                        
                        Button("Process Ticket") {
                            processManualTicket()
                        }
                        .appBody()
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.black).opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .disabled(isProcessing || manualTicketNumber.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.darkGray))
        .onAppear { fetchUserRole() }
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
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("Done") { presentationMode.wrappedValue.dismiss() }
        } message: {
            Text(successMessage)
        }
    }
    
    private var canScanTickets: Bool {
        ["scanner", "siteAdmin", "venueAdmin", "subAdmin"].contains(userRole)
    }
    
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
                            successMessage = "Ticket successfully marked as used!"
                            showingSuccess = true
                            manualTicketNumber = ""
                        }
                    }
                }
            }
        }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
