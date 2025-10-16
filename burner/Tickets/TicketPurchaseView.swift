import SwiftUI
import Kingfisher
import FirebaseAuth
import PassKit

struct TicketPurchaseView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    @State private var isPurchasing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var showApplePayButton = false
    @Environment(\.presentationMode) var presentationMode
    
    private var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Event summary - more compact
                HStack(spacing: 10) {
                    KFImage(URL(string: event.imageUrl))
                        .placeholder {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(event.venue)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Price info - simplified and compact
                HStack {
                    Text("Total")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("£\(String(format: "%.2f", event.price))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                
                // Apple Pay Button
                if showApplePayButton {
                    ApplePayButtonView {
                        handleApplePay()
                    }
                    .frame(height: 46)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                
                // Purchase button
                Button(action: {
                    purchaseTicket()
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.black)
                        }
                        
                        Text(isPurchasing ? "Processing..." : "Purchase Ticket")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 23))
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 20)
                .padding(.top, showApplePayButton ? 0 : 4)
                .padding(.bottom, 12)
            }
            .background(Color.black)
            .presentationDetents([.height(showApplePayButton ? 240 : 200)])
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(isSuccess ? "Success!" : "Purchase Failed"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .onAppear {
                showApplePayButton = ApplePayHandler.canMakePayments()
            }
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
        
        isPurchasing = true
        
        ApplePayHandler.shared.startPayment(
            eventName: event.name,
            amount: event.price,
            onSuccess: { payment in
                self.processPurchaseWithPayment(eventId: eventId, payment: payment)
            },
            onFailure: { error in
                DispatchQueue.main.async {
                    self.isPurchasing = false
                    self.alertMessage = error.localizedDescription
                    self.isSuccess = false
                    self.showingAlert = true
                }
            }
        )
    }
    
    private func processPurchaseWithPayment(eventId: String, payment: PKPayment) {
        viewModel.purchaseTicket(eventId: eventId) { success, error in
            DispatchQueue.main.async {
                isPurchasing = false
                
                if success {
                    alertMessage = "Ticket purchased successfully! Check your ticket in the profile tab."
                    isSuccess = true
                    showingAlert = true
                } else {
                    alertMessage = error ?? "Purchase failed. Please try again."
                    isSuccess = false
                    showingAlert = true
                }
            }
        }
    }
    
    private func purchaseTicket() {
        print("maxTickets: \(event.maxTickets), ticketsSold: \(event.ticketsSold)")
        print("availableTickets: \(availableTickets)")
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
        
        isPurchasing = true
        
        viewModel.purchaseTicket(eventId: eventId) { [self] success, error in
            DispatchQueue.main.async {
                isPurchasing = false
                
                if success {
                    alertMessage = "Ticket purchased successfully! Check your ticket in the profile tab."
                    isSuccess = true
                    showingAlert = true
                } else {
                    alertMessage = error ?? "Purchase failed. Please try again."
                    isSuccess = false
                    showingAlert = true
                }
            }
        }
    }
}
