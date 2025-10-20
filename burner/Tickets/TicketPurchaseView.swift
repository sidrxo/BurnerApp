import SwiftUI
import Kingfisher
import FirebaseAuth
import PassKit
import Combine

struct TicketPurchaseView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    @StateObject private var paymentService = StripePaymentService()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var showApplePayButton = false
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
                
                // Apple Pay Button
                if showApplePayButton {
                    Button(action: {
                        handleApplePay()
                    }) {
                        HStack(spacing: 8) {
                            if paymentService.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                                Text("Processing...")
                                    .appFont(size: 22)
                            } else {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 20))
                                Text("Pay")
                                    .appFont(size: 22)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(paymentService.isProcessing ? Color.gray.opacity(0.5) : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 23))
                        .overlay(
                            RoundedRectangle(cornerRadius: 23)
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }
                    .disabled(paymentService.isProcessing)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                
                // Card payment button (future implementation)
                Button(action: {
                    // TODO: Implement card payment flow
                    alertMessage = "Card payment coming soon! Please use Apple Pay."
                    isSuccess = false
                    showingAlert = true
                }) {
                    HStack(spacing: 8) {
                        Text("Pay with")
                            .appFont(size: 22)
                            .foregroundColor(.black)
                        
                        Image(systemName: "creditcard")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 23))
                }
                .padding(.horizontal, 20)
                .padding(.top, showApplePayButton ? 0 : 4)
                .padding(.bottom, 12)
            }
        }
        .presentationDetents([.height(showApplePayButton ? 260 : 220)])
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
        .onAppear {
            showApplePayButton = PKPaymentAuthorizationController.canMakePayments(
                usingNetworks: [.visa, .masterCard, .amex, .discover]
            )
        }
    }
    
    private func handleApplePay() {
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
        
        paymentService.processApplePayPayment(
            eventName: event.name,
            amount: event.price,
            eventId: event.id ?? "2"
        ) { result in
            DispatchQueue.main.async {
                if result.success {
                    alertMessage = result.message
                    isSuccess = true
                    showingAlert = true
                    
                    // Refresh events to update ticket count
                    viewModel.fetchEvents()
                } else {
                    alertMessage = result.message
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
