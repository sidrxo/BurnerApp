import SwiftUI
import Kingfisher
import FirebaseAuth
import StripePaymentSheet

struct TicketPurchaseView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    @StateObject private var paymentService = StripePaymentService()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @Environment(\.presentationMode) var presentationMode
    
    private var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Event summary
                VStack(spacing: 4) {
                    Text(event.name)
                        .appSectionHeader()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(event.venue)
                        .appBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
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
                
                // Payment Button
                if paymentService.isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                        Text("Processing...")
                            .appFont(size: 22)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.gray.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 23))
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                } else {
                    Button(action: {
                        handlePayment()
                    }) {
                        Text("Buy Ticket")
                            .appFont(size: 22)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 23))
                            .overlay(
                                RoundedRectangle(cornerRadius: 23)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                    .disabled(paymentService.isProcessing)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
            }
        }
        .presentationDetents([.height(220)])
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
        .onChange(of: paymentService.isPaymentSheetReady) { oldValue, newValue in
            if newValue {
                presentPaymentSheet()
            }
        }
    }
    
    private func presentPaymentSheet() {
        print("🔵 Attempting to present payment sheet")
        
        guard let paymentSheet = paymentService.paymentSheet else {
            print("❌ Payment sheet is nil")
            paymentService.isPaymentSheetReady = false
            return
        }
        
        // Get the presenting view controller (the one that presented this sheet)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Could not get root view controller")
            alertMessage = "Unable to present payment sheet"
            isSuccess = false
            showingAlert = true
            paymentService.isPaymentSheetReady = false
            return
        }
        
        // Find the topmost view controller that's not already presenting
        func getTopmostViewController(from viewController: UIViewController) -> UIViewController {
            if let presented = viewController.presentedViewController {
                return getTopmostViewController(from: presented)
            }
            return viewController
        }
        
        let presentingVC = getTopmostViewController(from: rootViewController)
        
        print("✅ Presenting payment sheet from: \(type(of: presentingVC))")
        
        paymentSheet.present(from: presentingVC) { result in
            print("🔵 Payment sheet completed with result: \(result)")
            handlePaymentSheetResult(result)
            paymentService.paymentSheet = nil
        }
    }
    
    private func handlePayment() {
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
        
        print("🔵 Starting payment flow for event: \(eventId)")
        
        paymentService.processPayment(
            eventName: event.name,
            amount: event.price,
            eventId: eventId
        ) { result in
            if !result.success {
                print("❌ Payment setup failed: \(result.message)")
                alertMessage = result.message
                isSuccess = false
                showingAlert = true
            }
        }
    }
    
    private func handlePaymentSheetResult(_ result: PaymentSheetResult) {
        print("🔵 Processing payment sheet result")
        
        guard let paymentIntentId = paymentService.currentPaymentIntentId else {
            print("❌ No payment intent ID found")
            alertMessage = "Payment session expired"
            isSuccess = false
            showingAlert = true
            return
        }
        
        print("🔵 Payment intent ID: \(paymentIntentId)")
        
        paymentService.onPaymentCompletion(result: result, paymentIntentId: paymentIntentId) { ticketResult in
            DispatchQueue.main.async {
                if ticketResult.success {
                    print("✅ Ticket created successfully: \(ticketResult.ticketId ?? "unknown")")
                    alertMessage = ticketResult.message
                    isSuccess = true
                    showingAlert = true
                    
                    // Refresh events to update ticket count
                    viewModel.fetchEvents()
                } else {
                    print("❌ Ticket creation failed: \(ticketResult.message)")
                    alertMessage = ticketResult.message
                    isSuccess = false
                    showingAlert = true
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
