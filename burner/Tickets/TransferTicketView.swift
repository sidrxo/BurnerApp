import SwiftUI
import Supabase

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

    // Access Supabase Client
    private var client: SupabaseClient {
        return SupabaseManager.shared.client
    }

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
        
        guard let ticketId = ticketWithEvent.ticket.id, !ticketId.isEmpty else {
            errorMessage = "Invalid ticket ID. Please try again."
            showErrorAlert = true
            return
        }
        
        guard let eventId = ticketWithEvent.event.id, !eventId.isEmpty else {
            errorMessage = "Invalid event ID. Please try again."
            showErrorAlert = true
            return
        }

        isTransferring = true

        Task {
            do {
                let payload: [String: String] = [
                    "ticketId": ticketId,
                    "recipientEmail": recipientEmail,
                    "eventId": eventId
                ]
                
                // Invoke Supabase Edge Function
                let response: Any = try await client.functions.invoke(
                    "transfer-ticket", // Ensure your Edge Function is named this in Supabase
                    options: FunctionInvokeOptions(
                        body: payload
                    )
                )
                
                // Parse response manually if needed, or trust the error throw
                await MainActor.run {
                    isTransferring = false
                    
                    // If we got here, it's likely success, but check response structure if your function returns specific success flags
                    if let data = response as? [String: Any],
                       let success = data["success"] as? Bool, success == true {
                        print("✅ Transfer successful")
                        showTransferSuccess = true
                        recipientEmail = ""
                    } else {
                         // If no error threw, but success isn't true, show a generic error
                         // (Depends on how your Edge Function returns data)
                        if let data = response as? [String: Any], let msg = data["message"] as? String {
                             errorMessage = msg
                        } else {
                            // Fallback for successful execution containing valid JSON
                             print("✅ Transfer successful")
                             showTransferSuccess = true
                             recipientEmail = ""
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isTransferring = false
                    print("❌ Transfer error: \(error)")
                    
                    // Parse Supabase Function Error
                    let errorMsg = error.localizedDescription
                    if errorMsg.contains("Recipient must have") {
                        errorMessage = "The recipient email is not registered on the app."
                    } else if errorMsg.contains("Ticket not found") {
                        errorMessage = "Ticket not found or you don't have permission."
                    } else if errorMsg.contains("already has a ticket") {
                        errorMessage = "The recipient already has a ticket for this event."
                    } else if errorMsg.contains("Invalid ticket status") {
                        errorMessage = "This ticket cannot be transferred (it may have been used)."
                    } else {
                        // Extract message from specific Supabase error types if available, otherwise default
                        errorMessage = "Transfer failed: \(errorMsg)"
                    }
                    showErrorAlert = true
                }
            }
        }
    }
}
