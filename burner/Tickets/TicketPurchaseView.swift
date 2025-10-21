import SwiftUI
import Kingfisher
import FirebaseAuth
import PassKit
@_spi(STP) import StripePaymentSheet

struct TicketPurchaseView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    @StateObject private var paymentService = StripePaymentService()

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var showCardInput = false
    @State private var cardParams: STPPaymentMethodCardParams?
    @State private var isCardValid = false
    @Environment(\.presentationMode) var presentationMode
    
    private var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Event summary

                    // Price info
                    HStack {
                        Text("Total")
                            .appBody()
                            .foregroundColor(.gray)

                        Spacer()

                        Text("£\(String(format: "%.2f", event.price))")
                            .appBody()
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.top, 10)


                    if paymentService.isProcessing {
                        // Processing state
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                            Text("Processing...")
                                .appFont(size: 23)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 23))
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    } else if showCardInput {
                        // Card input view
                        VStack(spacing: 12) {
                            CardInputView(cardParams: $cardParams, isValid: $isCardValid)
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                // Cancel button
                                Button(action: {
                                    withAnimation {
                                        showCardInput = false
                                        cardParams = nil
                                        isCardValid = false
                                    }
                                }) {
                                    Text("Cancel")
                                        .appBody()
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 46)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 23))
                                }

                                // Pay button
                                Button(action: handleCardPayment) {
                                    Text("Pay £\(String(format: "%.2f", event.price))")
                                        .appBody()
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 46)
                                        .background(isCardValid ? Color.white.opacity(0.15) : Color.gray.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 23))
                                }
                                .disabled(!isCardValid)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 4)
                    } else {
                        // Payment method selection
                        VStack(spacing: 12) {
                            // Apple Pay Button
                            if ApplePayHandler.canMakePayments() {
                                ApplePayButtonView {
                                    handleApplePayPayment()
                                }
                                .frame(height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 23))
                                .padding(.horizontal, 20)
                                .overlay(
                                       RoundedRectangle(cornerRadius: 23)
                                           .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                   )
                            }

                            // Or divider
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                Text("or")
                                    .appBody()
                                    .foregroundColor(.gray)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 40)

                            // Pay with Card button
                            Button(action: {
                                withAnimation {
                                    showCardInput = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Buy with")
                                    Image(systemName: "creditcard")
                                }
                                .font(.appFont(size: 23))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 23))
                                    .overlay(
                                           RoundedRectangle(cornerRadius: 23)
                                               .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                       )
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 10)
                    }

                    Spacer(minLength: 12)
                }
            
        }
        .presentationDetents([.height(showCardInput ? 380 : 320)])
        .presentationDragIndicator(.visible)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(isSuccess ? "Success!" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }

    private func handleApplePayPayment() {
        guard let eventId = event.id else {
            alertMessage = "Invalid event"
            isSuccess = false
            showingAlert = true
            return
        }

        guard Auth.auth().currentUser != nil else {
            alertMessage = "Please log in to purchase a ticket"
            isSuccess = false
            showingAlert = true
            return
        }

        // Check if Apple Pay is available
        guard ApplePayHandler.canMakePayments() else {
            alertMessage = "Apple Pay is not available on this device"
            isSuccess = false
            showingAlert = true
            return
        }

        print("🔵 Starting Apple Pay flow for event: \(eventId)")

        paymentService.processApplePayPayment(
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                if result.success {
                    print("✅ Ticket created successfully: \(result.ticketId ?? "unknown")")
                    self.alertMessage = result.message
                    self.isSuccess = true
                    self.showingAlert = true

                    // Refresh events to update ticket count
                    self.viewModel.fetchEvents()
                } else {
                    print("❌ Payment failed: \(result.message)")
                    self.alertMessage = result.message
                    self.isSuccess = false
                    self.showingAlert = true
                }
            }
        }
    }

    private func handleCardPayment() {
        guard let eventId = event.id else {
            alertMessage = "Invalid event"
            isSuccess = false
            showingAlert = true
            return
        }

        guard Auth.auth().currentUser != nil else {
            alertMessage = "Please log in to purchase a ticket"
            isSuccess = false
            showingAlert = true
            return
        }

        guard let cardParams = cardParams, isCardValid else {
            alertMessage = "Please enter valid card details"
            isSuccess = false
            showingAlert = true
            return
        }

        print("🔵 Starting card payment flow for event: \(eventId)")

        paymentService.processCardPayment(
            cardParams: cardParams,
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                if result.success {
                    print("✅ Ticket created successfully: \(result.ticketId ?? "unknown")")
                    self.alertMessage = result.message
                    self.isSuccess = true
                    self.showingAlert = true

                    // Refresh events to update ticket count
                    self.viewModel.fetchEvents()

                    // Reset card input
                    self.showCardInput = false
                    self.cardParams = nil
                    self.isCardValid = false
                } else {
                    print("❌ Payment failed: \(result.message)")
                    self.alertMessage = result.message
                    self.isSuccess = false
                    self.showingAlert = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TicketPurchaseView(
        event: Event(
            name: "Test Event",
            venue: "Test Venue",
            price: 25.0,
            maxTickets: 100,
            ticketsSold: 50,
            imageUrl: "",
            isFeatured: false
        ),
        viewModel: EventViewModel(
            eventRepository: EventRepository(),
            ticketRepository: TicketRepository(),
            purchaseService: PurchaseService()
        )
    )
    .preferredColorScheme(.dark)
}
