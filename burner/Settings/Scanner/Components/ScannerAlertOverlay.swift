import SwiftUI

/// Manages all alert overlays for the scanner view
struct ScannerAlertOverlay: View {
    @Binding var showingError: Bool
    @Binding var errorMessage: String
    @Binding var showingSuccess: Bool
    @Binding var successMessage: String
    @Binding var showingAlreadyUsed: Bool
    let alreadyUsedDetails: AlreadyUsedTicket?

    var body: some View {
        Group {
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
    }
}

struct AlreadyUsedTicket {
    let ticketNumber: String
    let eventName: String
    let userName: String
    let scannedAt: String
    let scannedBy: String
    let scannedByEmail: String?
}
