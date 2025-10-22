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
    @State private var showSavedCards = false // ✅ NEW: Show saved cards
    @State private var cardParams: STPPaymentMethodCardParams?
    @State private var isCardValid = false
    @State private var selectedSavedCard: StripePaymentService.PaymentMethodInfo? // ✅ NEW
    @Environment(\.presentationMode) var presentationMode
    
    private var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
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
                    cardInputSection
                } else if showSavedCards {
                    // ✅ NEW: Saved cards selection
                    savedCardsSection
                } else {
                    // Payment method selection
                    paymentMethodSelection
                }

                Spacer(minLength: 12)
            }
            
        }
        .presentationDetents([.height(showCardInput ? 420 : showSavedCards ? 520 : 320)])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Load saved payment methods
            Task {
                try? await paymentService.fetchPaymentMethods()
            }
        }
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
    
    // MARK: - Card Input Section
    private var cardInputSection: some View {
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
    }
    
    // ✅ NEW: Saved Cards Section
    private var savedCardsSection: some View {
        VStack(spacing: 12) {
            Text("Select Payment Method")
                .appBody()
                .foregroundColor(.white)
                .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(paymentService.paymentMethods) { method in
                        Button(action: {
                            selectedSavedCard = method
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "creditcard.fill")
                                    .font(.appIcon)
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(method.brand.capitalized) •••• \(method.last4)")
                                        .appBody()
                                        .foregroundColor(.white)
                                    
                                    Text("Expires \(method.expMonth)/\(method.expYear)")
                                        .appCaption()
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if selectedSavedCard?.id == method.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.appIcon)
                                        .foregroundColor(.green)
                                }
                                
                                if method.isDefault {
                                    Text("DEFAULT")
                                        .appCaption()
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            .padding(12)
                            .background(selectedSavedCard?.id == method.id ? Color.white.opacity(0.1) : Color.gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(maxHeight: 250)
            .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                // Cancel button
                Button(action: {
                    withAnimation {
                        showSavedCards = false
                        selectedSavedCard = nil
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

                // Pay with selected card button
                Button(action: handleSavedCardPayment) {
                    Text("Pay £\(String(format: "%.2f", event.price))")
                        .appBody()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(selectedSavedCard != nil ? Color.white.opacity(0.15) : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 23))
                }
                .disabled(selectedSavedCard == nil)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Payment Method Selection
    private var paymentMethodSelection: some View {
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

            // ✅ UPDATED: Show saved cards or new card option
            if !paymentService.paymentMethods.isEmpty {
                // Use saved card button - with creditcard.fill icon and forced font size 23
                Button(action: {
                    withAnimation {
                        showSavedCards = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("Buy with")
                            .font(.system(size: 23))
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 23))
                    }
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
            } else {
                // No saved cards - show add card button
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
        }
        .padding(.top, 4)
        .padding(.horizontal, 10)
    }

    // MARK: - Apple Pay Handler
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

    // MARK: - New Card Payment Handler
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
    
    // ✅ NEW: Saved Card Payment Handler
    private func handleSavedCardPayment() {
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

        guard let savedCard = selectedSavedCard else {
            alertMessage = "Please select a payment method"
            isSuccess = false
            showingAlert = true
            return
        }

        print("🔵 Starting saved card payment flow for event: \(eventId)")

        paymentService.processSavedCardPayment(
            paymentMethodId: savedCard.id,
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
                    self.viewModel.fetchEvents()
                    
                    // Reset selection
                    self.showSavedCards = false
                    self.selectedSavedCard = nil
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
