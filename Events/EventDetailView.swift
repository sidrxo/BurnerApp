import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFunctions
import Firebase
import PassKit

struct EventDetailView: View {
    let event: Event
    @State private var isBookmarked = false
    @State private var showingPurchase = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var userHasTicket = false
    @StateObject private var viewModel = EventViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabBarVisibility: TabBarVisibility
    
    var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    var buttonText: String {
        if userHasTicket {
            return "Ticket Purchased"
        } else if availableTickets > 0 {
            return "Buy Ticket - £\(String(format: "%.2f", event.price))"
        } else {
            return "Sold Out"
        }
    }
    
    var buttonColor: Color {
        if userHasTicket {
            return .green
        } else if availableTickets > 0 {
            return .white
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    var buttonTextColor: Color {
        if userHasTicket {
            return .white
        } else if availableTickets > 0 {
            return .black
        } else {
            return .gray
        }
    }
    
    var isButtonDisabled: Bool {
        return userHasTicket || availableTickets == 0
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image Section
                    ZStack {
                        KFImage(URL(string: event.imageUrl))
                            .placeholder {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    )
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(height: 500)
                            .clipped()
                        
                        // Gradient overlay
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.clear,
                                Color.clear,
                                Color.black.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 500)
                        
                        // Event info overlay
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            
                            Text(event.name)
                                .font(.appTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                        .font(.appCallout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Text(event.date.formatted(.dateTime.hour().minute()))
                                        .font(.appCallout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(event.venue)
                                        .font(.appCallout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    
                    // Content Section
                    VStack(spacing: 24) {
                        // Price and availability
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ticket Price")
                                    .font(.appFootnote)
                                    .foregroundColor(.gray)
                                
                                Text("£\(String(format: "%.2f", event.price))")
                                    .font(.appTitle2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(userHasTicket ? "Status" : "Available")
                                    .font(.appFootnote)
                                    .foregroundColor(.gray)
                                
                                if userHasTicket {
                                    Text("Purchased")
                                        .font(.appCallout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                } else {
                                    Text("\(availableTickets) tickets")
                                        .font(.appCallout)
                                        .fontWeight(.medium)
                                        .foregroundColor(availableTickets > 0 ? .green : .red)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Purchase limit notice
                        if !userHasTicket {
                            VStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                Text("One ticket per person limit")
                                    .font(.appCallout)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        }
                        
                        // Description
                        if let description = event.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About")
                                    .font(.appTitle3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(description)
                                    .font(.appBody)
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        }
                        
                        // Event details
                        VStack(spacing: 16) {
                            Text("Event Details")
                                .font(.appTitle3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                EventDetailRow(
                                    icon: "calendar",
                                    title: "Date & Time",
                                    value: event.date.formatted(.dateTime.weekday(.wide).day().month().year().hour().minute())
                                )
                                
                                EventDetailRow(
                                    icon: "location",
                                    title: "Venue",
                                    value: event.venue
                                )
                                
                                EventDetailRow(
                                    icon: "ticket",
                                    title: "Tickets Sold",
                                    value: "\(event.ticketsSold) / \(event.maxTickets)"
                                )
                                
                                EventDetailRow(
                                    icon: "person.fill",
                                    title: "Purchase Limit",
                                    value: "1 ticket per person"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            
            // Floating bottom bar
            VStack {
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        isBookmarked.toggle()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        if !userHasTicket && availableTickets > 0 {
                            showingPurchase = true
                        }
                    }) {
                        Text(buttonText)
                            .font(.appHeadline)
                            .fontWeight(.semibold)
                            .foregroundColor(buttonTextColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(buttonColor)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .disabled(isButtonDisabled)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.8),
                            Color.black
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 150)
                )
            }
        }
        .onAppear {
            tabBarVisibility.hideTabBar()
            checkUserTicketStatus()
        }
        .onDisappear {
            tabBarVisibility.showTabBar()
        }
        .sheet(isPresented: $showingPurchase) {
            TicketPurchaseView(event: event, viewModel: viewModel)
                .onDisappear {
                    // Refresh ticket status when purchase sheet is dismissed
                    checkUserTicketStatus()
                }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        checkUserTicketStatus()
                    }
                }
            )
        }
        .onReceive(viewModel.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                alertMessage = errorMessage
                isSuccess = false
                showingAlert = true
                viewModel.clearMessages()
            }
        }
        .onReceive(viewModel.$successMessage) { successMessage in
            if let successMessage = successMessage {
                alertMessage = successMessage
                isSuccess = true
                showingAlert = true
                viewModel.clearMessages()
                checkUserTicketStatus()
            }
        }
    }
    
    private func checkUserTicketStatus() {
        guard let eventId = event.id else { return }
        
        viewModel.checkUserTicketStatus(for: eventId) { hasTicket in
            DispatchQueue.main.async {
                self.userHasTicket = hasTicket
            }
        }
    }
}

// MARK: - Apple Pay Button View (UI Only)
struct ApplePayButtonView: View {
    var body: some View {
        if PKPaymentAuthorizationController.canMakePayments() {
            RepresentedApplePayButton()
                .frame(maxWidth: .infinity)
        } else {
            EmptyView()
        }
    }
}

struct RepresentedApplePayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        // Button is UI only, no action
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
}

// MARK: - Event Detail Row
struct EventDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview
#Preview {
    EventDetailView(event: Event(
        name: "Sample Event",
        venue: "Sample Venue",
        date: Date(),
        price: 25.0,
        maxTickets: 100,
        ticketsSold: 50,
        imageUrl: "",
        isFeatured: false,
        description: "This is a sample event description for testing the event detail view."
    ))
    .preferredColorScheme(.dark)
}
