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
                Spacer()

                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    // Title
                    VStack(spacing: 8) {
                        Text("Transfer Ticket")
                            .appHero()
                            .foregroundColor(.white)

                        Text("Enter the recipient's email address")
                            .appBody()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

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

                        if let error = transferError {
                            Text(error)
                                .appCaption()
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 24)

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
                    .padding(.horizontal, 24)

                    // Transfer Button
                    Button(action: {
                        showConfirmation = true
                    }) {
                        ZStack {
                            if isTransferring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("Transfer")
                                    .appBody()
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isTransferring || recipientEmail.isEmpty)
                    .padding(.horizontal, 24)
                }

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
