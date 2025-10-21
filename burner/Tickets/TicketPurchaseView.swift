import SwiftUI
import Kingfisher
import FirebaseAuth
import PassKit

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
                
                // Apple Pay Button
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
                    ApplePayButtonView {
                        handleApplePayPayment()
                    }
                    .frame(height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 23))
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                    .disabled(paymentService.isProcessing)
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
