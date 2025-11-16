import SwiftUI
import CodeScanner
import FirebaseAuth

struct ScannerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @StateObject private var viewModel = ScannerViewModel()

    @State private var showManualEntry = false
    @State private var manualTicketNumber: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Main Content
            contentView

            // Alert Overlays
            ScannerAlertOverlay(
                showingError: $viewModel.showingError,
                errorMessage: $viewModel.errorMessage,
                showingSuccess: $viewModel.showingSuccess,
                successMessage: $viewModel.successMessage,
                showingAlreadyUsed: $viewModel.showingAlreadyUsed,
                alreadyUsedDetails: viewModel.alreadyUsedDetails
            )

            // Manual Entry Sheet
            if showManualEntry {
                ManualEntrySheet(
                    isPresented: $showManualEntry,
                    ticketNumber: $manualTicketNumber,
                    onSubmit: { ticketId in
                        viewModel.scanTicket(manualTicketId: ticketId)
                    }
                )
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showManualEntry)
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isCheckingScanner {
            loadingView
        } else if !viewModel.canScanTickets {
            accessDeniedView
        } else if viewModel.selectedEvent == nil {
            eventSelectionView
        } else {
            scannerViewFinder
        }
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
                Text("Role: \(viewModel.userRole.isEmpty ? "not loaded" : viewModel.userRole)")
                    .appSecondary()
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 8)

                Text("Scanner Active: \(viewModel.isScannerActive ? "Yes" : "No")")
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
            SettingsHeaderSection(title: "Select Event")
                .padding(.horizontal, 20)
                .padding(.top, 20)

            if viewModel.isLoadingEvents {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    Text("Loading events...")
                        .appBody()
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.todaysEvents.isEmpty {
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
                        ForEach(viewModel.todaysEvents, id: \.id) { event in
                            Button(action: {
                                viewModel.selectEvent(event)
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
                if let selectedEvent = viewModel.selectedEvent {
                    VStack(spacing: 8) {
                        Text(selectedEvent.name)
                            .appBody()
                            .foregroundColor(.white)
                            .fontWeight(.semibold)

                        Text(selectedEvent.venue)
                            .appSecondary()
                            .foregroundColor(.white.opacity(0.7))

                        Button(action: {
                            viewModel.clearEventSelection()
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
                if viewModel.isProcessing {
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

    // MARK: - Scan Handler
    private func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let scanResult):
            print("🔍 [SCANNER DEBUG] QR Code scanned: \(scanResult.string)")
            viewModel.scanTicket(qrCodeData: scanResult.string)

        case .failure(let error):
            print("🔍 [SCANNER DEBUG] ❌ Scan failed: \(error.localizedDescription)")
            viewModel.errorMessage = "Scanning failed: \(error.localizedDescription)"
            viewModel.showingError = true
        }
    }
}
