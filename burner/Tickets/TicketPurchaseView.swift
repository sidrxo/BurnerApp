// TicketPurchaseView.swift - Updated for Supabase

import SwiftUI
import Kingfisher
import Supabase
import PassKit
@_spi(STP) import StripePaymentSheet
import AVKit

struct TicketPurchaseView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    
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
    @State private var pendingTicketId: String?

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    
    private var paymentService: StripePaymentService {
        appState.stripePaymentService
    }
    
    enum PurchaseStep {
        case paymentMethod
        case cardInput
        case savedCards
    }
    
    private var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    private var currentTab: AppTab {
        coordinator.selectedTab
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                eventHeader
                
                Divider()
                    .background(Color.white.opacity(0.05))
                
                mainContent
            }
            .opacity(showLoadingSuccess ? 0 : 1)
            
            if showLoadingSuccess {
                LoadingSuccessView(
                    isLoading: $isLoadingPayment,
                    size: 80,
                    lineWidth: 8,
                    color: .white,
                    onAnimationComplete: {
                        self.transitionToTicketDetail()
                    }
                )
            }
            
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
            ToolbarItem(placement: .principal) {
                Text("Purchase Ticket")
                    .appBody()
                    .foregroundColor(.white)
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInSheetView(
                showingSignIn: $showSignIn,
                isOnboarding: false
            )
        }
        .onChange(of: appState.authService.currentUser) { oldValue, newValue in
            if newValue != nil, let action = pendingPaymentAction {
                print("🟢 [TicketView] Auth state changed: user signed in. Executing pending action.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    action()
                    pendingPaymentAction = nil
                }
            }
        }
        .onAppear {
            print("🟡 [TicketView] View appeared. Starting fetch and prepare tasks.")
            Task {
                async let methodsResult: Void? = try? paymentService.fetchPaymentMethods()
                async let prepResult: Void = preparePaymentIntent()
                _ = await (methodsResult, prepResult)
                print("🟢 [TicketView] Fetch/Prepare tasks completed.")
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if currentStep == .paymentMethod {
            paymentMethodView
        } else {
            cardPaymentView
        }
    }

    private var paymentMethodView: some View {
        VStack(spacing: 20) {
            priceSummary

            if !appState.burnerManager.hasCompletedSetup {
                burnerModeDisclaimer
            }

            Divider()
                .background(Color.white.opacity(0.05))
                .padding(.horizontal, 20)

            Spacer(minLength: 0)
            
            termsAndConditions
            
            paymentButtons
        }
        .padding(.vertical, 20)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var cardPaymentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            priceSummary

            Divider()
                .background(Color.white.opacity(0.05))
                .padding(.horizontal, 20)

            Spacer()
            
            VStack(spacing: 20) {
                if currentStep == .cardInput {
                    cardInputSection
                } else if currentStep == .savedCards {
                    savedCardsSection
                }
                
                payButton
            }
        }
        .padding(.vertical, 20)
    }

    private var termsAndConditions: some View {
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
    }

    private var paymentButtons: some View {
        VStack(spacing: 12) {
            if ApplePayHandler.canMakePayments() {
                ApplePayButtonView(action: {
                    print("🟡 [TicketView] Apple Pay button tapped.")
                    checkAuthAndProceed {
                        handleApplePayPayment()
                    }
                })
                .frame(height: 50)
                .disabled(hasInitiatedPurchase)
            }

            Button(action: {
                print("🟡 [TicketView] Buy with Card button tapped. Current step: \(currentStep)")
                withAnimation {
                    if !paymentService.paymentMethods.isEmpty {
                        currentStep = .savedCards
                    } else {
                        currentStep = .cardInput
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Text("Buy with")
                        .font(.system(size: 20, weight: .medium))

                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundColor(.black)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(hasInitiatedPurchase)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var payButton: some View {
        VStack(spacing: 12) {
            if currentStep == .cardInput {
                Button(action: {
                    print("🟡 [TicketView] Pay with New Card button tapped.")
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
                    print("🟡 [TicketView] Pay with Saved Card button tapped.")
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
    
    private func checkAuthAndProceed(action: @escaping () -> Void) {
        if appState.authService.currentUser == nil {
            print("🟡 [TicketView] User not authenticated. Storing pending action and showing sign-in.")
            pendingPaymentAction = action
            showSignIn = true
        } else {
            print("🟢 [TicketView] User authenticated. Proceeding with action.")
            action()
        }
    }

    private func preparePaymentIntent() async {
        guard let eventId = event.id else { return }
        guard appState.authService.currentUser != nil else { return }
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

            Text("You'll need to setup BURNER Mode after purchase to access your ticket.")
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
                        print("🟡 [TicketView] Switched to Card Input step.")
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
        print("🟡 [TicketView] Initiating Apple Pay transaction.")
        guard !hasInitiatedPurchase else {
            return
        }

        guard let eventId = event.id else {
            showError("Invalid event")
            return
        }

        guard appState.authService.currentUser != nil else {
            showError("Please log in to purchase a ticket")
            return
        }

        guard ApplePayHandler.canMakePayments() else {
            showError("Apple Pay is not available on this device")
            return
        }

        hasInitiatedPurchase = true
        
        isLoadingPayment = true
        showLoadingSuccess = true
        print("🟢 [TicketView] Apple Pay UI triggered. Waiting for payment service result.")

        paymentService.processApplePayPayment(
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            print("🟡 [TicketView] Apple Pay result received. Success: \(result.success)")
            DispatchQueue.main.async {
                self.hasInitiatedPurchase = false
                
                if result.success {
                    print("🟢 [TicketView] Apple Pay SUCCESS. Fetching events and stopping loading. Ticket ID: \(result.ticketId ?? "N/A")")
                    self.viewModel.fetchEvents()
                    self.appState.ticketsViewModel.fetchUserTickets()
                    self.pendingTicketId = result.ticketId
                    self.isLoadingPayment = false
                    
                } else {
                    self.showLoadingSuccess = false
                    if !result.message.isEmpty {
                        self.showError(result.message)
                    }
                }
            }
        }
    }
    
    private func handleCardPayment() {
        print("🟡 [TicketView] Initiating Card Payment transaction.")
        guard !hasInitiatedPurchase else {
            return
        }

        guard let eventId = event.id,
              let cardParams = cardParams,
              isCardValid else { return }

        guard appState.authService.currentUser != nil else {
            showError("Please log in to purchase a ticket")
            return
        }

        hasInitiatedPurchase = true
        
        isLoadingPayment = true
        showLoadingSuccess = true
        print("🟢 [TicketView] Card Payment UI triggered. Waiting for payment service result.")

        paymentService.processCardPayment(
            cardParams: cardParams,
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            print("🟡 [TicketView] Card Payment result received. Success: \(result.success)")
            DispatchQueue.main.async {
                self.hasInitiatedPurchase = false
                
                if result.success {
                    print("🟢 [TicketView] Card Payment SUCCESS. Fetching events and stopping loading. Ticket ID: \(result.ticketId ?? "N/A")")
                    self.viewModel.fetchEvents()
                    self.appState.ticketsViewModel.fetchUserTickets()
                    self.pendingTicketId = result.ticketId
                    self.isLoadingPayment = false
                    
                } else {
                    self.showLoadingSuccess = false
                    self.showError(result.message)
                }
            }
        }
    }
    
    private func handleSavedCardPayment() {
        print("🟡 [TicketView] Initiating Saved Card Payment transaction.")
        guard !hasInitiatedPurchase else {
            return
        }

        guard let eventId = event.id,
              let savedCard = selectedSavedCard else { return }

        guard appState.authService.currentUser != nil else {
            showError("Please log in to purchase a ticket")
            return
        }

        hasInitiatedPurchase = true
        
        isLoadingPayment = true
        showLoadingSuccess = true
        print("🟢 [TicketView] Saved Card Payment UI triggered. Waiting for payment service result.")

        paymentService.processSavedCardPayment(
            paymentMethodId: savedCard.id,
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            print("🟡 [TicketView] Saved Card Payment result received. Success: \(result.success)")
            DispatchQueue.main.async {
                self.hasInitiatedPurchase = false
                
                if result.success {
                    print("🟢 [TicketView] Saved Card Payment SUCCESS. Fetching events and stopping loading. Ticket ID: \(result.ticketId ?? "N/A")")
                    self.viewModel.fetchEvents()
                    self.appState.ticketsViewModel.fetchUserTickets()
                    self.pendingTicketId = result.ticketId
                    self.isLoadingPayment = false
                    
                } else {
                    self.showLoadingSuccess = false
                    self.showError(result.message)
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        isSuccess = false
        showingAlert = true
    }

    // MARK: - Transition to Ticket Detail
    
    private func transitionToTicketDetail() {
        print("🟡 [TicketView] Starting UI transition (dismiss).")
        self.pushTicketDetail(ticketId: pendingTicketId, event: self.event)
    }
    
    private func pushTicketDetail(ticketId: String?, event: Event) {
        let tab = self.currentTab
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            
            guard let definitiveTicketId = ticketId else {
                coordinator.showSuccess(
                    title: "Purchase Successful",
                    message: "Your ticket for \(event.name) is now available in the Tickets tab, but an error occurred during navigation."
                )
                
                coordinator.pop(in: tab)
                return
            }
            
            self.waitForTicketSync(ticketId: definitiveTicketId, event: event, tab: tab)
        }
    }
    
    private func waitForTicketSync(ticketId: String, event: Event, tab: AppTab, retryCount: Int = 0) {
        let maxRetries = 5
        let delay: TimeInterval = 0.2

        let matchingTickets = appState.ticketsViewModel.tickets.filter { ticket in
            // CHANGED: ticket.ticketId instead of ticket.id
            ticket.ticketId == ticketId && ticket.eventId == event.id && ticket.status == "confirmed"
        }

        if let ticket = matchingTickets.first {
            let ticketWithEvent = TicketWithEventData(ticket: ticket, event: event)
            print("🟢 [TicketView] Found definitive ticket (\(ticketId)) after \(retryCount) retries. Pushing TicketDetailView.")

            coordinator.pop(in: tab)
            coordinator.navigate(to: .ticketDetail(ticketWithEvent, shouldAnimate: true), in: tab)
        } else if retryCount < maxRetries {
            print("🟡 [TicketView] Waiting for ticket ID \(ticketId) to sync (\(retryCount + 1)/\(maxRetries))...")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.waitForTicketSync(ticketId: ticketId, event: event, tab: tab, retryCount: retryCount + 1)
            }
        } else {
            coordinator.showSuccess(
                title: "Purchase Successful",
                message: "Your ticket for \(event.name) is now available in the Tickets tab."
            )
            coordinator.pop(in: tab)
        }
    }
}

// MARK: - Apple Pay Button View

struct ApplePayButtonView: UIViewRepresentable {
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .continue, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func buttonTapped() {
            action()
        }
    }
}
