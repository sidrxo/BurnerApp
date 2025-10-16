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
    
    // Get screen height for responsive sizing
    private let screenHeight = UIScreen.main.bounds.height
    
    // Calculate responsive hero height based on screen size
    private var heroHeight: CGFloat {
        // Use 45% of screen height, with min/max bounds
        let calculatedHeight = screenHeight * 0.45
        return max(300, min(calculatedHeight, 500))
    }
    
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
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Image Section - Now responsive
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
                                .frame(width: geometry.size.width, height: heroHeight)
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
                            .frame(width: geometry.size.width, height: heroHeight)
                            
                            // Event info overlay - positioned at bottom
                            VStack {
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(event.name)
                                        .appFont(size: min(32, geometry.size.width * 0.08), weight: .black)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.date.formatted(.dateTime.hour().minute()))
                                                .appFont(size: 16, weight: .medium)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(event.venue)
                                                .appFont(size: 16, weight: .medium)
                                                .foregroundColor(.white.opacity(0.9))
                                                .multilineTextAlignment(.trailing)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
                        .frame(height: heroHeight)
                        
                        // Content Section - More compact spacing
                        VStack(spacing: 16) {
                            // Price section only
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ticket Price")
                                        .appFont(size: 13)
                                        .foregroundColor(.gray)
                                    
                                    Text("£\(String(format: "%.2f", event.price))")
                                        .appFont(size: 22, weight: .bold)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            
                            // Description - more compact
                            if let description = event.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About")
                                        .appFont(size: 17, weight: .semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(description)
                                        .appFont(size: 15)
                                        .foregroundColor(.gray)
                                        .lineSpacing(2)
                                        .lineLimit(6)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            }
                            
                            // Event details - more compact
                            VStack(spacing: 12) {
                                Text("Event Details")
                                    .appFont(size: 17, weight: .semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 8) {
                                    EventDetailRow(
                                        icon: "calendar",
                                        title: "Date & Time",
                                        value: event.date.formatted(.dateTime.weekday(.abbreviated).day().month().year().hour().minute())
                                    )
                                    
                                    EventDetailRow(
                                        icon: "location",
                                        title: "Venue",
                                        value: event.venue
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Bottom spacing for floating button
                            Spacer(minLength: 100)
                        }
                    }
                }
                
                // Floating bottom bar
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            isBookmarked.toggle()
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            if !userHasTicket && availableTickets > 0 {
                                showingPurchase = true
                            }
                        }) {
                            Text(buttonText)
                                .appFont(size: 16, weight: .semibold)
                                .foregroundColor(buttonTextColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(buttonColor)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        .disabled(isButtonDisabled)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
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
                        .frame(height: 120)
                    )
                }
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


struct RepresentedApplePayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        // Button is UI only, no action
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
}

// MARK: - Event Detail Row - More compact
struct EventDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .appFont(size: 14, weight: .medium)
                .foregroundColor(.white)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .appFont(size: 13)
                    .foregroundColor(.gray)
                
                Text(value)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview
#Preview {
    EventDetailView(event: Event(
        name: "fabric Presents: Nina Kraviz - Electronic Music Experience",
        venue: "fabric London",
        date: Date(),
        price: 25.0,
        maxTickets: 100,
        ticketsSold: 50,
        imageUrl: "",
        isFeatured: false,
        description: "The Russian techno queen returns to fabric with her hypnotic blend of acid and experimental electronic music."
    ))
    .preferredColorScheme(.dark)
}
