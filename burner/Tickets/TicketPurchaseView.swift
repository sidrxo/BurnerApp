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
    @State private var selectedSavedCard: PaymentMethodInfo?
    @State private var hasInitiatedPurchase = false // ✅ Prevent duplicate purchases

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
                        .background(Color.white.opacity(0.05))
                    
                    Group {
                        if currentStep == .paymentMethod {
                            VStack(spacing: 20) {
                                // Price summary
                                priceSummary
                                
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.horizontal, 20)
                                
                                Spacer(minLength: 0)
                                
                                // ✅ UPDATED: Single line terms with clickable links
                                VStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Text("By continuing, you agree to our")
                                            .appCaption()
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        NavigationLink(destination: TermsOfServiceView()) {
                                            Text("Terms of Service")
                                                .appCaption()
                                                .foregroundColor(.white)
                                                .underline()
                                        }
                                        
                                        Text("&")
                                            .appCaption()
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        NavigationLink(destination: PrivacyPolicyView()) {
                                            Text("Privacy Policy")
                                                .appCaption()
                                                .foregroundColor(.white)
                                                .underline()
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                                
                                // ✅ UPDATED: Matching button styles
                                VStack(spacing: 12) {
                                    if ApplePayService.canMakePayments() {
                                        Button(action: {
                                            handleApplePayPayment()
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "applelogo")
                                                    .font(.appIcon)
                                                
                                                Text("BUY WITH APPLE PAY")
                                                    .font(.appFont(size: 17))
                                            }
                                            .foregroundColor(.black)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .accessibilityLabel("Buy with Apple Pay")
                                        .disabled(hasInitiatedPurchase)
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
                                        HStack(spacing: 12) {
                                            Image(systemName: "creditcard.fill")
                                                .font(.appIcon)
                                            
                                            Text("BUY WITH CARD")
                                                .font(.appFont(size: 17))
                                        }
                                        .foregroundColor(.white)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(hasInitiatedPurchase)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                            .padding(.vertical, 20)
                            .frame(maxHeight: .infinity, alignment: .top)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                // Price summary
                                priceSummary

                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.horizontal, 20)

                                Spacer()
                                
                                // PAY BUTTON - Fixed at bottom with card input directly above
                                if currentStep == .cardInput || currentStep == .savedCards {
                                    VStack(spacing: 20) {
                                        // ✅ UPDATED: Card input placed directly above the pay button
                                        if currentStep == .cardInput {
                                            cardInputSection
                                        } else if currentStep == .savedCards {
                                            savedCardsSection
                                        }
                                        
                                        VStack(spacing: 12) {
                                            if currentStep == .cardInput {
                                                Button(action: { handleCardPayment() }) {
                                                    HStack(spacing: 12) {
                                                        Image(systemName: "creditcard.fill").font(.appIcon)
                                                        Text("PAY £\(String(format: "%.2f", event.price))")
                                                            .font(.appFont(size: 17))
                                                    }
                                                    .foregroundColor(isCardValid ? .black : .gray)
                                                    .frame(height: 50)
                                                    .frame(maxWidth: .infinity)
                                                    .background(isCardValid ? .white : Color.gray.opacity(0.5))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                                }
                                                .disabled(!isCardValid || hasInitiatedPurchase)
                                            } else if currentStep == .savedCards {
                                                Button(action: { handleSavedCardPayment() }) {
                                                    HStack(spacing: 12) {
                                                        Image(systemName: "creditcard.fill").font(.appIcon)
                                                        Text("PAY £\(String(format: "%.2f", event.price))")
                                                            .font(.appFont(size: 17))
                                                    }
                                                    .foregroundColor(selectedSavedCard != nil ? .black : .gray)
                                                    .frame(height: 50)
                                                    .frame(maxWidth: .infinity)
                                                    .background(selectedSavedCard != nil ? .white : Color.gray.opacity(0.5))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                                }
                                                .disabled(selectedSavedCard == nil || hasInitiatedPurchase)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 20)
                                    }
                                }
                            }
                            .padding(.vertical, 20)
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
                                // ✅ FIXED: Reset hasInitiatedPurchase when user goes back/cancels
                                hasInitiatedPurchase = false
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
        guard ApplePayService.canMakePayments() else { return }
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
    
    // ✅ UPDATED: Card input section with minimal spacing
    private var cardInputSection: some View {
        VStack(spacing: 0) {
                CardInputView(
                cardParams: $cardParams,
                isValid: $isCardValid
            )
            .frame(height: 100)
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
        // ✅ Prevent duplicate purchase attempts
        guard !hasInitiatedPurchase else {
            print("⚠️ Purchase already in progress, ignoring duplicate tap")
            return
        }

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

        guard ApplePayService.canMakePayments() else {
            alertMessage = "Apple Pay is not available on this device"
            isSuccess = false
            showingAlert = true
            return
        }

        // ✅ Mark purchase as initiated
        hasInitiatedPurchase = true

        paymentService.processApplePayPayment(
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                self.hasInitiatedPurchase = false  // ✅ Always reset
                
                // ✅ Only show alert if there's a message
                if !result.message.isEmpty {
                    self.alertMessage = result.message
                    self.isSuccess = result.success
                    self.showingAlert = true
                }
                
                if result.success {
                    self.viewModel.fetchEvents()
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func handleCardPayment() {
        // ✅ Prevent duplicate purchase attempts
        guard !hasInitiatedPurchase else {
            print("⚠️ Purchase already in progress, ignoring duplicate tap")
            return
        }

        guard let eventId = event.id,
              let cardParams = cardParams,
              isCardValid else { return }

        guard Auth.auth().currentUser != nil else {
            alertMessage = "Please log in to purchase a ticket"
            isSuccess = false
            showingAlert = true
            return
        }

        // ✅ Mark purchase as initiated
        hasInitiatedPurchase = true

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
                // ✅ Reset flag after completion
                self.hasInitiatedPurchase = false
                if result.success {
                    self.viewModel.fetchEvents()
                }
            }
        }
    }
    
    private func handleSavedCardPayment() {
        // ✅ Prevent duplicate purchase attempts
        guard !hasInitiatedPurchase else {
            print("⚠️ Purchase already in progress, ignoring duplicate tap")
            return
        }

        guard let eventId = event.id,
              let savedCard = selectedSavedCard else { return }

        guard Auth.auth().currentUser != nil else {
            alertMessage = "Please log in to purchase a ticket"
            isSuccess = false
            showingAlert = true
            return
        }

        // ✅ Mark purchase as initiated
        hasInitiatedPurchase = true

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
                // ✅ Reset flag after completion
                self.hasInitiatedPurchase = false
                if result.success {
                    self.viewModel.fetchEvents()
                }
            }
        }
    }
}
