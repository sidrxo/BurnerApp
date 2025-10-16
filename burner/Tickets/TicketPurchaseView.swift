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
            VStack(spacing: 24) {
                // Event summary
                HStack(spacing: 12) {
                    KFImage(URL(string: event.imageUrl))
                        .placeholder {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(event.venue)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(event.date.formatted(.dateTime.weekday(.abbreviated).day().month()))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Ticket info
                VStack(spacing: 16) {
                    Text("Ticket Purchase")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Ticket Price")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("£\(String(format: "%.2f", event.price))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        HStack {
                            Text("Total")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("£\(String(format: "%.2f", event.price))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Price breakdown
                VStack(spacing: 12) {
                    HStack {
                        Text("1 Ticket")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("£\(String(format: "%.2f", event.price))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                
                // Apple Pay Button
                if showApplePayButton {
                    ApplePayButtonView {
                        handleApplePay()
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 20)
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
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .navigationTitle("Buy Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
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
                // Check if Apple Pay is available
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
                // Payment authorized - now process with your backend
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
        // Here you would send the payment token to your backend
        // The token is in: payment.token.paymentData
        
        // For now, we'll just call the existing purchase method
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
