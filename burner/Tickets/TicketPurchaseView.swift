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
    @State private var currentStep: PurchaseStep = .paymentMethod
    @State private var cardParams: STPPaymentMethodCardParams?
    @State private var isCardValid = false
    @State private var selectedSavedCard: StripePaymentService.PaymentMethodInfo?
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    enum PurchaseStep {
        case paymentMethod
        case cardInput
        case savedCards
    }
    
    private var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with event info
                    eventHeader
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Main content based on step
                    ScrollView {
                        VStack(spacing: 20) {
                            // Price summary
                            priceSummary
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.horizontal, 20)
                            
                            // Content based on current step
                            Group {
                                switch currentStep {
                                case .paymentMethod:
                                    paymentMethodSelection
                                case .cardInput:
                                    cardInputSection
                                case .savedCards:
                                    savedCardsSection
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Bottom action button
                    if !paymentService.isProcessing {
                        bottomActionButton
                    } else {
                        processingView
                    }
                }
                
                if showingAlert {
                    CustomAlertView(
                        title: isSuccess ? "Success!" : "Error",
                        description: alertMessage,
                        primaryAction: {
                            showingAlert = false
                            if isSuccess {
                                presentationMode.wrappedValue.dismiss()
                            }
                        },
                        primaryActionTitle: "OK",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1001)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if currentStep != .paymentMethod {
                            withAnimation {
                                currentStep = .paymentMethod
                                selectedSavedCard = nil
                                cardParams = nil
                                isCardValid = false
                            }
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: currentStep != .paymentMethod ? "chevron.left" : "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Purchase Ticket")
                        .appBody()
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            Task {
                try? await paymentService.fetchPaymentMethods()
            }
        }
    }
    
    // MARK: - Event Header
    private var eventHeader: some View {
        HStack(spacing: 12) {
            // Event image
            KFImage(URL(string: event.imageUrl))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        )
                }
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .appBody()
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(event.venue)
                    .appCaption()
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    // MARK: - Price Summary
    private var priceSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Ticket Price")
                    .appBody()
                    .foregroundColor(.gray)
                Spacer()
                Text("£\(String(format: "%.2f", event.price))")
                    .appBody()
                    .foregroundColor(.white)
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            HStack {
                Text("Total")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("£\(String(format: "%.2f", event.price))")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Payment Method Selection
    private var paymentMethodSelection: some View {
        VStack(spacing: 16) {
            Text("Choose Payment Method")
                .appBody()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            // Apple Pay
            if ApplePayHandler.canMakePayments() {
                Button(action: handleApplePayPayment) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 24))
                        Text("Apple Pay")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
            }
            
            // Saved Cards
            if !paymentService.paymentMethods.isEmpty {
                Button(action: {
                    withAnimation {
                        currentStep = .savedCards
                    }
                }) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 20))
                        Text("Saved Cards")
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                        Text("\(paymentService.paymentMethods.count)")
                            .appCaption()
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
            }
            
            // Add New Card
            Button(action: {
                withAnimation {
                    currentStep = .cardInput
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text(paymentService.paymentMethods.isEmpty ? "Card Payment" : "Add New Card")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .foregroundColor(.white)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Card Input Section
    private var cardInputSection: some View {
        VStack(spacing: 16) {
            Text("Enter Card Details")
                .appBody()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            CardInputView(cardParams: $cardParams, isValid: $isCardValid)
                .padding(.horizontal, 20)
            
            // Security badge
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                Text("Secured by Stripe")
                    .appCaption()
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Saved Cards Section
    private var savedCardsSection: some View {
        VStack(spacing: 16) {
            Text("Select Payment Method")
                .appBody()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ForEach(paymentService.paymentMethods) { method in
                    Button(action: {
                        withAnimation {
                            selectedSavedCard = method
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Card brand icon
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 24))
                                .foregroundColor(selectedSavedCard?.id == method.id ? .green : .white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(method.brand.capitalized)
                                        .appBody()
                                        .foregroundColor(.white)
                                    
                                    if method.isDefault {
                                        Text("DEFAULT")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                                
                                Text("•••• \(method.last4)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Expires \(method.expMonth)/\(method.expYear)")
                                    .appCaption()
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if selectedSavedCard?.id == method.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(16)
                        .background(
                            selectedSavedCard?.id == method.id ?
                            Color.green.opacity(0.1) :
                            Color.white.opacity(0.05)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedSavedCard?.id == method.id ?
                                    Color.green : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Button(action: handlePrimaryAction) {
                Text(primaryActionTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isPrimaryActionEnabled ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isPrimaryActionEnabled ? Color.white : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isPrimaryActionEnabled)
            .padding(20)
        }
        .background(Color.black)
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("Processing Payment...")
                    .appBody()
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(20)
        }
        .background(Color.black)
    }
    
    // MARK: - Computed Properties
    private var primaryActionTitle: String {
        switch currentStep {
        case .paymentMethod:
            return "Select Payment Method"
        case .cardInput:
            return isCardValid ? "Pay £\(String(format: "%.2f", event.price))" : "Enter Card Details"
        case .savedCards:
            return selectedSavedCard != nil ? "Pay £\(String(format: "%.2f", event.price))" : "Select a Card"
        }
    }
    
    private var isPrimaryActionEnabled: Bool {
        switch currentStep {
        case .paymentMethod:
            return false
        case .cardInput:
            return isCardValid
        case .savedCards:
            return selectedSavedCard != nil
        }
    }
    
    private func handlePrimaryAction() {
        switch currentStep {
        case .paymentMethod:
            break
        case .cardInput:
            handleCardPayment()
        case .savedCards:
            handleSavedCardPayment()
        }
    }
    
    // MARK: - Payment Handlers
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

        paymentService.processApplePayPayment(
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                self.alertMessage = result.message
                self.isSuccess = result.success
                self.showingAlert = true
                if result.success {
                    self.viewModel.fetchEvents()
                }
            }
        }
    }

    private func handleCardPayment() {
        guard let eventId = event.id,
              let cardParams = cardParams,
              isCardValid else { return }

        guard Auth.auth().currentUser != nil else {
            alertMessage = "Please log in to purchase a ticket"
            isSuccess = false
            showingAlert = true
            return
        }

        paymentService.processCardPayment(
            cardParams: cardParams,
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                self.alertMessage = result.message
                self.isSuccess = result.success
                self.showingAlert = true
                if result.success {
                    self.viewModel.fetchEvents()
                }
            }
        }
    }
    
    private func handleSavedCardPayment() {
        guard let eventId = event.id,
              let savedCard = selectedSavedCard else { return }

        guard Auth.auth().currentUser != nil else {
            alertMessage = "Please log in to purchase a ticket"
            isSuccess = false
            showingAlert = true
            return
        }

        paymentService.processSavedCardPayment(
            paymentMethodId: savedCard.id,
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                self.alertMessage = result.message
                self.isSuccess = result.success
                self.showingAlert = true
                if result.success {
                    self.viewModel.fetchEvents()
                }
            }
        }
    }
}
