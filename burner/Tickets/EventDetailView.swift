import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFunctions
import Firebase
import PassKit

struct EventDetailView: View {
    let event: Event
    
    // Use environment objects instead of creating new instances
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var eventViewModel: EventViewModel
    
    @State private var showingPurchase = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var userHasTicket = false
    @State private var showShareSheet = false
    @State private var showingAuthAlert = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabBarVisibility: TabBarVisibility
    @EnvironmentObject var appState: AppState
    
    // Get screen height for responsive sizing
    private let screenHeight = UIScreen.main.bounds.height
    
    // Calculate responsive hero height based on screen size
    private var heroHeight: CGFloat {
        // Use 45% of screen height, with min/max bounds
        let calculatedHeight = screenHeight * 0.40
        return max(300, min(calculatedHeight, 500))
    }
    
    var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }
    
    var buttonText: String {
        if userHasTicket {
            return "You already own a ticket."
        } else if availableTickets > 0 {
            return "Buy Ticket"
        } else {
            return "Sold Out"
        }
    }
    
    var buttonColor: Color {
        if userHasTicket {
            return Color.gray.opacity(0.3)
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
            return .white
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
                        // Hero Image Section - Extends under navigation bar
                        ZStack {
                            KFImage(URL(string: event.imageUrl))
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .appHero()
                                                .foregroundColor(.gray)
                                        )
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: heroHeight)
                                .clipped()
                            
                            // Gradient overlay that darkens the bottom
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.clear,
                                    Color.clear,
                                    Color.black.opacity(0.6),
                                    Color.black.opacity(0.9)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: geometry.size.width, height: heroHeight)
                            
                            // Event info overlay - positioned at bottom
                            VStack {
                                   Spacer()
                                   
                                   HStack {
                                       VStack(alignment: .leading, spacing: 12) {
                                           Text(event.name)
                                               .appHero()
                                               .foregroundColor(.white)
                                               .multilineTextAlignment(.leading)
                                               .fixedSize(horizontal: false, vertical: true)
                                       }
                                       
                                       Spacer()
                                   }
                                   .padding(.horizontal, 20)
                                   .padding(.bottom, 20)
                            }
                        }
                        .frame(height: heroHeight)
                        .ignoresSafeArea(edges: .top)
                        .padding(.bottom, 30)
                        
                        // Content Section - More compact spacing
                        VStack(spacing: 16) {
                           
                            // Description - more compact
                            if let description = event.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About")
                                        .appBody()
                                        .foregroundColor(.white)
                                    
                                    Text(description)
                                        .appBody()
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
        .appBody()                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                VStack(spacing: 8) {
                                    EventDetailRow(
                                        icon: "calendar",
                                        title: "Date & Time",
                                        value: (event.startTime ?? Date()).formatted(.dateTime.weekday(.abbreviated).day().month().year().hour().minute())
                                    )

                                    EventDetailRow(
                                        icon: "location",
                                        title: "Venue",
                                        value: event.venue
                                    )

                                    EventDetailRow(
                                        icon: "creditcard",
                                        title: "Price",
                                        value: "£\(String(format: "%.2f", event.price))"
                                    )

                                    // Genre/Tag row
                                    if let tags = event.tags, !tags.isEmpty {
                                        EventDetailRow(
                                            icon: "tag",
                                            title: "Genre",
                                            value: tags.joined(separator: ", ")
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            // Share button centered below event metadata
                            Button(action: {
                                showShareSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16))
                                    Text("Share Event")
                                        .appBody()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
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
                            Task {
                                await bookmarkManager.toggleBookmark(for: event)
                            }
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
    .appBody()                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            if !userHasTicket && availableTickets > 0 {
                                // Check if user is authenticated
                                if Auth.auth().currentUser == nil {
                                    showingAuthAlert = true
                                } else {
                                    showingPurchase = true
                                }
                            }
                        }) {
                            Text(buttonText)
                                .appBody()
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
        .navigationBarBackButtonHidden(false)
        .onAppear {
            tabBarVisibility.hideTabBar()
            checkUserTicketStatus()
        }
        .onDisappear {
            tabBarVisibility.showTabBar()
        }
        .sheet(isPresented: $showingPurchase) {
            TicketPurchaseView(event: event, viewModel: eventViewModel)
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // Refresh ticket status when purchase sheet is dismissed
                    checkUserTicketStatus()
                }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [generateShareText(), generateShareURL()])
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
        .onReceive(eventViewModel.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                alertMessage = errorMessage
                isSuccess = false
                showingAlert = true
                eventViewModel.clearMessages()
            }
        }
        .onReceive(eventViewModel.$successMessage) { successMessage in
            if let successMessage = successMessage {
                alertMessage = successMessage
                isSuccess = true
                showingAlert = true
                eventViewModel.clearMessages()
                checkUserTicketStatus()
            }
        }
        .customAlert(
            isPresented: $showingAuthAlert,
            title: "Sign In Required",
            message: "You need to be signed in to buy tickets.",
            primaryButtonTitle: "Sign In",
            primaryButtonAction: {
                appState.isSignInSheetPresented = true
            },
            secondaryButtonTitle: "Cancel",
            secondaryButtonAction: {}
        )
    }
    
    private func checkUserTicketStatus() {
        guard let eventId = event.id else { return }

        eventViewModel.checkUserTicketStatus(for: eventId) { hasTicket in
            DispatchQueue.main.async {
                self.userHasTicket = hasTicket
            }
        }
    }

    private func generateShareText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = event.startTime.map { dateFormatter.string(from: $0) } ?? "TBA"

        return """
        Check out this event on Burner!

        \(event.name)
        \(event.venue)
        \(dateString)

        £\(String(format: "%.2f", event.price))
        """
    }

    private func generateShareURL() -> URL {
        // Create a custom URL scheme for deep linking
        // Format: burner://event/{eventId}
        guard let eventId = event.id else {
            return URL(string: "burner://events")!
        }
        return URL(string: "burner://event/\(eventId)")!
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
                .font(.appIcon)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .appSecondary()
                    .foregroundColor(.gray)
                
                Text(value)
                    .appBody()
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

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        EventDetailView(event: Event(
            name: "fabric Presents: Nina Kraviz",
            venue: "fabric London",
            price: 25.0,
            maxTickets: 100,
            ticketsSold: 50,
            imageUrl: "https://placeholder.com/400x600",
            isFeatured: false,
            description: "The Russian techno queen returns to fabric with her hypnotic blend of acid and experimental electronic music."
        ))
        .environmentObject(TabBarVisibility(isDetailViewPresented: .constant(false)))
        .environmentObject(AppState().bookmarkManager)
        .environmentObject(AppState().eventViewModel)
    }
    .preferredColorScheme(.dark)
}
