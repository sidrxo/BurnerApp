import SwiftUI
import FirebaseFunctions

// MARK: - Transfer Ticket View
struct TransferTicketView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var recipientEmail = ""
    @State private var isTransferring = false
    @State private var showTransferSuccess = false
    @State private var showConfirmation = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showDisclaimerSlide = true
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // Slides using ZStack and Offset for smooth transitions
            ZStack {
                // Slide 0: Disclaimer
                VStack(spacing: 0) {
                    Spacer()

                    // Header
                    VStack(spacing: 0) {
                        TightHeaderText("NOT COMING", "ANYMORE?", alignment: .center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)

                    Text("Once transferred, you will no longer have access to this ticket. The recipient will receive a notification and the ticket will appear in their account.")
                        .appBody()
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                        .padding(.bottom, 30)

                    // Continue Button
                    BurnerButton("CONTINUE", style: .primary, maxWidth: 140) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.easeOut(duration: 0.3)) {
                            showDisclaimerSlide = false
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .offset(x: slideOffset(for: 0))
                .opacity(showDisclaimerSlide ? 1 : 0)
                .zIndex(showDisclaimerSlide ? 1 : 0)

                // Slide 1: Transfer Form
                VStack(spacing: 0) {
                    Spacer()

                    // Header
                    VStack(spacing: 0) {
                        TightHeaderText("TRANSFER", "TICKET", alignment: .center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)

                    // Email Input
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Recipient Email", text: $recipientEmail)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled(true)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.continue)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .appBody()
                            .onSubmit {
                                if !recipientEmail.isEmpty {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    showConfirmation = true
                                }
                            }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)

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
                .offset(x: slideOffset(for: 1))
                .opacity(showDisclaimerSlide ? 0 : 1)
                .zIndex(showDisclaimerSlide ? 0 : 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                        // Dismiss transfer view and navigate back to tickets list
                        presentationMode.wrappedValue.dismiss()
                        // Also dismiss the ticket detail view by popping the navigation stack
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            coordinator.pop()
                        }
                    },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }

            if showErrorAlert {
                CustomAlertView(
                    title: "Transfer Failed",
                    description: errorMessage,
                    primaryAction: {
                        showErrorAlert = false
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

    // Custom Slide Transition Logic
    private func slideOffset(for slide: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let currentSlide = showDisclaimerSlide ? 0 : 1
        return screenWidth * CGFloat(slide - currentSlide)
    }

    private func transferTicket() {
        guard !recipientEmail.isEmpty else { return }

        isTransferring = true

        let functions = Functions.functions()
        let transferFunction = functions.httpsCallable("transferTicket")

        // The backend function:
        // 1. Validates that the recipient doesn't already have a ticket for this event
        // 2. Validates ticket ownership and status
        // 3. Updates the ticket ownership

        transferFunction.call([
            "ticketId": ticketWithEvent.ticket.id ?? "",
            "recipientEmail": recipientEmail,
            "eventId": ticketWithEvent.event.id ?? ""
        ]) { result, error in
            DispatchQueue.main.async {
                isTransferring = false

                if let error = error as NSError? {
                    // Handle error - show in custom alert
                    if let message = error.userInfo["message"] as? String {
                        errorMessage = message
                    } else {
                        errorMessage = "Transfer failed. Please try again."
                    }
                    showErrorAlert = true
                    return
                }

                // Success
                showTransferSuccess = true
                recipientEmail = ""
            }
        }
    }
}
