// TicketPurchaseView.swift

import SwiftUI
import Kingfisher
import FirebaseAuth
import PassKit
@_spi(STP) import StripePaymentSheet
import AVKit

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
    @State private var hasInitiatedPurchase = false
    @State private var showSignIn = false
    @State private var pendingPaymentAction: (() -> Void)?
    @State private var showBurnerSetup = false
    @State private var isLoadingPayment = true
    @State private var showLoadingSuccess = false

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    
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
                
                // Main content
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

                                // Burner mode disclaimer if not set up
                                if !appState.burnerManager.hasCompletedSetup {
                                    burnerModeDisclaimer
                                }

                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.horizontal, 20)

                                Spacer(minLength: 0)
                                
                                // Terms and conditions
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
                                
                                // Payment buttons
                                VStack(spacing: 12) {
                                    if ApplePayHandler.canMakePayments() {
                                        Button(action: {
                                            checkAuthAndProceed {
                                                handleApplePayPayment()
                                            }
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "applelogo")
                                                    .font(.appIcon)

                                                Text("BUY WITH APPLE PAY")
                                                    .appButton()
                                            }
                                            .foregroundColor(.black)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white)
                                            .clipShape(Capsule())
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
                                                .appButton()
                                        }
                                        .foregroundColor(.white)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black.opacity(0.8))
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
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
                                        // Card input placed directly above the pay button
                                        if currentStep == .cardInput {
                                            cardInputSection
                                        } else if currentStep == .savedCards {
                                            savedCardsSection
                                        }
                                        
                                        VStack(spacing: 12) {
                                            if currentStep == .cardInput {
                                                Button(action: {
                                                    checkAuthAndProceed {
                                                        handleCardPayment()
                                                    }
                                                }) {
                                                    HStack(spacing: 12) {
                                                        Image(systemName: "creditcard.fill").font(.appIcon)
                                                        Text("PAY £\(String(format: "%.2f", event.price))")
                                                            .appButton()
                                                    }
                                                    .foregroundColor(isCardValid ? .black : .gray)
                                                    .frame(height: 50)
                                                    .frame(maxWidth: .infinity)
                                                    .background(isCardValid ? .white : Color.gray.opacity(0.5))
                                                    .clipShape(Capsule())
                                                }
                                                .disabled(!isCardValid || hasInitiatedPurchase)
                                            } else if currentStep == .savedCards {
                                                Button(action: {
                                                    checkAuthAndProceed {
                                                        handleSavedCardPayment()
                                                    }
                                                }) {
                                                    HStack(spacing: 12) {
                                                        Image(systemName: "creditcard.fill").font(.appIcon)
                                                        Text("PAY £\(String(format: "%.2f", event.price))")
                                                            .appButton()
                                                    }
                                                    .foregroundColor(selectedSavedCard != nil ? .black : .gray)
                                                    .frame(height: 50)
                                                    .frame(maxWidth: .infinity)
                                                    .background(selectedSavedCard != nil ? .white : Color.gray.opacity(0.5))
                                                    .clipShape(Capsule())
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
                .opacity(showLoadingSuccess ? 0 : 1)
                
                // ✅ ERROR ALERT (only shown for errors)
                if showingAlert && !isSuccess {
                    CustomAlertView(
                        title: "Error",
                        description: alertMessage,
                        primaryAction: {
                            showingAlert = false
                        },
                        primaryActionTitle: "OK",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1004)
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
        .fullScreenCover(isPresented: $showLoadingSuccess) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                LoadingSuccessView(
                    isLoading: $isLoadingPayment,
                    size: 80,
                    lineWidth: 8,
                    color: .white
                )
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInSheetView(
                showingSignIn: $showSignIn,
                onSkip: {
                    pendingPaymentAction = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showBurnerSetup) {
            BurnerModeSetupView(
                burnerManager: appState.burnerManager,
                onSkip: {
                    showBurnerSetup = false
                    presentationMode.wrappedValue.dismiss()
                    // Navigate to ticket detail after dismissing purchase view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        navigateToTicketDetail()
                    }
                }
            )
        }
        .onChange(of: Auth.auth().currentUser) { oldValue, newValue in
            if newValue != nil, let action = pendingPaymentAction {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    action()
                    pendingPaymentAction = nil
                }
            }
        }
        .onChange(of: isLoadingPayment) { oldValue, newValue in
            // When loading completes (success), wait for animation to finish then show next step
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showLoadingSuccess = false
                    if !appState.burnerManager.hasCompletedSetup {
                        showBurnerSetup = true
                    } else {
                        // Burner already set up, dismiss and navigate to ticket detail
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            navigateToTicketDetail()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                async let methodsResult: Void? = try? paymentService.fetchPaymentMethods()
                async let prepResult: Void = preparePaymentIntent()
                _ = await (methodsResult, prepResult)
            }
        }
    }
    
    private func checkAuthAndProceed(action: @escaping () -> Void) {
        if Auth.auth().currentUser == nil {
            pendingPaymentAction = action
            showSignIn = true
        } else {
            action()
        }
    }

    private func preparePaymentIntent() async {
        guard let eventId = event.id else { return }
        guard Auth.auth().currentUser != nil else { return }
        guard ApplePayHandler.canMakePayments() else { return }
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

    private var burnerModeDisclaimer: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .appFont(size: 20)
                .foregroundColor(.white.opacity(0.7))

            Text("You'll need to complete Burner Mode setup after purchase to access your ticket.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
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
                                        .appFont(size: 8, weight: .bold)
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
                                        .appCaption()
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
                                            .appFont(size: 8, weight: .bold)
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
        guard !hasInitiatedPurchase else {
            print("⚠️ Purchase already in progress, ignoring duplicate tap")
            return
        }

        guard let eventId = event.id else {
            showError("Invalid event")
            return
        }

        guard Auth.auth().currentUser != nil else {
            showError("Please log in to purchase a ticket")
            return
        }

        guard ApplePayHandler.canMakePayments() else {
            showError("Apple Pay is not available on this device")
            return
        }

        hasInitiatedPurchase = true
        
        // ✅ Show loading animation
        isLoadingPayment = true
        showLoadingSuccess = true

        paymentService.processApplePayPayment(
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                self.hasInitiatedPurchase = false
                
                if result.success {
                    self.viewModel.fetchEvents()
                    // ✅ Trigger success animation
                    self.isLoadingPayment = false
                } else {
                    // ✅ Hide loading and show error
                    self.showLoadingSuccess = false
                    if !result.message.isEmpty {
                        self.showError(result.message)
                    }
                }
            }
        }
    }
    
    private func handleCardPayment() {
        guard !hasInitiatedPurchase else {
            print("⚠️ Purchase already in progress, ignoring duplicate tap")
            return
        }

        guard let eventId = event.id,
              let cardParams = cardParams,
              isCardValid else { return }

        guard Auth.auth().currentUser != nil else {
            showError("Please log in to purchase a ticket")
            return
        }

        hasInitiatedPurchase = true
        
        // ✅ Show loading animation
        isLoadingPayment = true
        showLoadingSuccess = true

        paymentService.processCardPayment(
            cardParams: cardParams,
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                self.hasInitiatedPurchase = false
                
                if result.success {
                    self.viewModel.fetchEvents()
                    // ✅ Trigger success animation
                    self.isLoadingPayment = false
                } else {
                    // ✅ Hide loading and show error
                    self.showLoadingSuccess = false
                    self.showError(result.message)
                }
            }
        }
    }
    
    private func handleSavedCardPayment() {
        guard !hasInitiatedPurchase else {
            print("⚠️ Purchase already in progress, ignoring duplicate tap")
            return
        }

        guard let eventId = event.id,
              let savedCard = selectedSavedCard else { return }

        guard Auth.auth().currentUser != nil else {
            showError("Please log in to purchase a ticket")
            return
        }

        hasInitiatedPurchase = true
        
        // ✅ Show loading animation
        isLoadingPayment = true
        showLoadingSuccess = true

        paymentService.processSavedCardPayment(
            paymentMethodId: savedCard.id,
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            DispatchQueue.main.async {
                self.hasInitiatedPurchase = false
                
                if result.success {
                    self.viewModel.fetchEvents()
                    // ✅ Trigger success animation
                    self.isLoadingPayment = false
                } else {
                    // ✅ Hide loading and show error
                    self.showLoadingSuccess = false
                    self.showError(result.message)
                }
            }
        }
    }
    
    // ✅ Helper function to show errors
    private func showError(_ message: String) {
        alertMessage = message
        isSuccess = false
        showingAlert = true
    }

    // Helper function to navigate to the newly purchased ticket detail
    private func navigateToTicketDetail() {
        // First, switch to tickets tab
        coordinator.selectTab(.tickets)

        // Wait a moment for Firestore to create the ticket and for tickets to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Refresh tickets to get the newly created ticket
            Task {
                // Find the ticket for this event
                let matchingTickets = appState.ticketsViewModel.tickets.filter { ticket in
                    ticket.eventId == event.id && ticket.status == "confirmed"
                }

                if let ticket = matchingTickets.first {
                    // Create TicketWithEventData and navigate
                    let ticketWithEvent = TicketWithEventData(ticket: ticket, event: event)
                    coordinator.navigate(to: .ticketDetail(ticketWithEvent), in: .tickets)
                } else {
                    // If ticket not found yet, try again after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let retryTickets = appState.ticketsViewModel.tickets.filter { ticket in
                            ticket.eventId == event.id && ticket.status == "confirmed"
                        }

                        if let ticket = retryTickets.first {
                            let ticketWithEvent = TicketWithEventData(ticket: ticket, event: event)
                            coordinator.navigate(to: .ticketDetail(ticketWithEvent), in: .tickets)
                        }
                    }
                }
            }
        }
    }
}
