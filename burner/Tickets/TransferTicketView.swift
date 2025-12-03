import SwiftUI
import FirebaseFunctions

// MARK: - Transfer Ticket View
struct TransferTicketView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var recipientEmail = ""
    @State private var isTransferring = false
    @State private var transferError: String?
    @State private var showTransferSuccess = false
    @State private var showConfirmation = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed top spacing for consistent alignment
                Color.clear.frame(height: 100)

                // Header positioned at consistent height
                VStack(spacing: 0) {
                    TightHeaderText("TRANSFER", "TICKET", alignment: .center)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 120)

                Text("Enter the recipient's email address")
                    .appBody()
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
                    .padding(.bottom, 40)

                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Recipient Email", text: $recipientEmail)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .appBody()

                    if let error = transferError {
                        Text(error)
                            .appCaption()
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)

                // Disclaimer
                VStack(spacing: 8) {
                    Text("Important")
                        .appCaption()
                        .foregroundColor(.white)

                    Text("Once transferred, you will no longer have access to this ticket. The recipient will receive a notification and the ticket will appear in their account.")
                        .appCaption()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

                // Transfer Button
                BurnerButton("TRANSFER", style: .primary, maxWidth: 140) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showConfirmation = true
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isTransferring || recipientEmail.isEmpty)
                .opacity(recipientEmail.isEmpty ? 0.5 : 1.0)

                Spacer()
            }

            if showConfirmation {
                CustomAlertView(
                    title: "Confirm Transfer",
                    description: "Are you sure you want to transfer this ticket to \(recipientEmail)? This action cannot be undone.",
                    cancelAction: { showConfirmation = false },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        showConfirmation = false
                        transferTicket()
                    },
                    primaryActionTitle: "Transfer",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }

            if showTransferSuccess {
                CustomAlertView(
                    title: "Transfer Successful",
                    description: "Ticket has been transferred successfully!",
                    primaryAction: {
                        showTransferSuccess = false
                        presentationMode.wrappedValue.dismiss()
                    },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func transferTicket() {
        guard !recipientEmail.isEmpty else { return }

        isTransferring = true
        transferError = nil

        let functions = Functions.functions()
        let transferFunction = functions.httpsCallable("transferTicket")

        // The backend function should:
        // 1. Validate that the recipient doesn't already have a ticket for this event
        // 2. Send a push notification to the recipient when transfer is successful
        // 3. Update the ticket ownership

        transferFunction.call([
            "ticketId": ticketWithEvent.ticket.id ?? "",
            "recipientEmail": recipientEmail,
            "eventId": ticketWithEvent.event.id ?? ""
        ]) { result, error in
            DispatchQueue.main.async {
                isTransferring = false

                if let error = error as NSError? {
                    // Handle error
                    if let errorMessage = error.userInfo["message"] as? String {
                        transferError = errorMessage
                    } else {
                        transferError = "Transfer failed. Please try again."
                    }
                    return
                }

                // Success - push notification is sent by the backend
                showTransferSuccess = true
                recipientEmail = ""
            }
        }
    }
}
