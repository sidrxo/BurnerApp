// TicketPurchaseView.swift

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
                    // Header
                    eventHeader
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    Group {
                        if currentStep == .paymentMethod {
                            VStack(spacing: 20) {
                                // Price summary
                                priceSummary
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                    .padding(.horizontal, 20)
                                
                                Spacer(minLength: 0)
                                
                                // ✅ Buttons section
                                VStack(spacing: 12) {
                                    if ApplePayHandler.canMakePayments() {
                                        Button(action: {
                                            handleApplePayPayment()
                                        }) {
                                            HStack(spacing: 6) {
                                                Text("Buy with")
                                                Image(systemName: "applelogo")
                                                    .font(.system(size: 24, weight: .semibold))
                                                    .baselineOffset(-1)
                                            }
                                            .appSectionHeader()
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 50)
                                            .background(Color.black)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .accessibilityLabel("Buy with Apple Pay")
                                    }
                                    
                                    
                                    Button(action: {
                                        withAnimation {
                                            if !paymentService.paymentMethods.isEmpty {
                                                currentStep = .savedCards
                                            } else {
                                                currentStep = .cardInput
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Text("Buy with")
                                            Image(systemName: "creditcard.fill")
                                        }
                                        .appSectionHeader()
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                                
                                // Terms
                                Text("By continuing, you agree to our\nTerms of Service and Privacy Policy.")
                                    .appCaption()
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .padding(.bottom, 20)
                            }
                            .padding(.vertical, 20)
                            .frame(maxHeight: .infinity, alignment: .top)
                        } else {
                            ScrollView {
                                VStack(spacing: 20) {
                                    priceSummary
                                    
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.horizontal, 20)
                                    
                                    Group {
                                        switch currentStep {
                                        case .paymentMethod:
                                            EmptyView()
                                        case .cardInput:
                                            cardInputSection
                                        case .savedCards:
                                            savedCardsSection
                                        }
                                    }
                                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                                }
                                .padding(.vertical, 20)
                                .padding(.bottom, 20)
                            }
                        }
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

                // Loading indicator overlay
                if paymentService.isProcessing {
                    ZStack {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()

                        CustomLoadingIndicator(size: 50)
                    }
                    .transition(.opacity)
                    .zIndex(1002)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(false)
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
                            .appBody()
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
                // Run these in parallel and await both
                async let methodsResult: Void? = try? paymentService.fetchPaymentMethods()
                async let prepResult: Void = preparePaymentIntent()
                _ = await (methodsResult, prepResult)
            }
        }
    }
    
    private func preparePaymentIntent() async {
        guard let eventId = event.id else { return }
        guard Auth.auth().currentUser != nil else { return }
        guard ApplePayHandler.canMakePayments() else { return }
        // `preparePayment` is not async; don't await it.
        paymentService.preparePayment(eventId: eventId)
    }
    
    private var eventHeader: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: event.imageUrl))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .appCard()
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
                    .appBody()
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(16)
    }
    
    private var priceSummary: some View {
        HStack {
            Text("Total")
                .appCard()
                .foregroundColor(.white)
            Spacer()
            Text("£\(String(format: "%.2f", event.price))")
                .appCard()
                .foregroundColor(.white)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private var cardInputSection: some View {
        VStack(spacing: 16) {
            Text("Enter Card Details")
                .appBody()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            CardInputView(
                cardParams: $cardParams,
                isValid: $isCardValid
            )
            .frame(height: 200)
            .padding(.horizontal, 20)
        }
    }
    
    private var savedCardsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Select Payment Method")
                    .appCard()
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentStep = .cardInput
                    }
                }) {
                    Text("Add New")
                        .appBody()
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(paymentService.paymentMethods) { method in
                    Button(action: {
                        withAnimation {
                            selectedSavedCard = method
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 40, height: 28)
                                
                                if method.brand.lowercased() == "visa" {
                                    Text("VISA")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                } else if method.brand.lowercased() == "mastercard" {
                                    HStack(spacing: -4) {
                                        Circle()
                                            .fill(Color.red.opacity(0.8))
                                            .frame(width: 12, height: 12)
                                        Circle()
                                            .fill(Color.orange.opacity(0.8))
                                            .frame(width: 12, height: 12)
                                    }
                                } else {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(method.brand.capitalized)
                                        .appCaption()
                                        .foregroundColor(.gray)
                                    
                                    if method.isDefault {
                                        Text("DEFAULT")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                    }
                                }
                                
                                Text("•••• \(method.last4)")
                                    .appBody()
                                    .foregroundColor(.white)
                                
                                Text("Expires \(method.expMonth)/\(method.expYear)")
                                    .appCaption()
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if selectedSavedCard?.id == method.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .appSectionHeader()
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
            eventId: eventId,
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
