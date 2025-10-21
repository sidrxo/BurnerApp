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
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabBarVisibility: TabBarVisibility
    
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

    private let metaGridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    private let tagColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 80), spacing: 8)
    ]

    private var isBookmarked: Bool {
        guard let eventId = event.id else { return false }
        return bookmarkManager.isBookmarked(eventId)
    }

    private var formattedDate: String {
        guard let start = event.startTime else { return "Date TBC" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: start)
    }

    private var weekdayText: String? {
        guard let start = event.startTime else { return nil }
        return start.formatted(.dateTime.weekday(.wide)).uppercased()
    }

    private var timeRangeText: String {
        guard let start = event.startTime else { return "Time TBC" }
        let startTime = start.formatted(.dateTime.hour().minute())

        if let end = event.endTime {
            let endTime = end.formatted(.dateTime.hour().minute())
            return "\(startTime) – \(endTime)"
        }

        return startTime
    }

    private var durationText: String? {
        guard let start = event.startTime, let end = event.endTime, end > start else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short

        if let formatted = formatter.string(from: start, to: end) {
            return "Duration \(formatted)"
        }

        return nil
    }

    private var priceText: String {
        "£\(String(format: "%.2f", event.price))"
    }

    private var priceSecondaryText: String {
        availableTickets > 0 ? "per ticket" : "last listed price"
    }

    private var ticketAvailabilityPrimary: String {
        availableTickets > 0 ? "\(availableTickets) left" : "Sold Out"
    }

    private var ticketAvailabilitySecondary: String {
        var parts: [String] = ["\(event.maxTickets) total"]
        if let status = event.status?.replacingOccurrences(of: "_", with: " "), !status.isEmpty {
            parts.append(status.capitalized)
        }
        return parts.joined(separator: " • ")
    }

    private var metaCards: [EventMetaCardData] {
        var cards: [EventMetaCardData] = [
            EventMetaCardData(
                title: "Date",
                primaryText: formattedDate,
                secondaryText: weekdayText
            ),
            EventMetaCardData(
                title: "Time",
                primaryText: timeRangeText,
                secondaryText: durationText
            ),
            EventMetaCardData(
                title: "Venue",
                primaryText: event.venue,
                secondaryText: nil
            ),
            EventMetaCardData(
                title: "Tickets",
                primaryText: ticketAvailabilityPrimary,
                secondaryText: ticketAvailabilitySecondary
            ),
            EventMetaCardData(
                title: "Price",
                primaryText: priceText,
                secondaryText: priceSecondaryText
            )
        ]

        if let category = event.category, !category.isEmpty {
            cards.append(
                EventMetaCardData(
                    title: "Category",
                    primaryText: category.capitalized,
                    secondaryText: nil
                )
            )
        }

        return cards
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
                            
                            // Gradient overlay with blur at bottom
                            ZStack {
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
                                
                                // Fading blur effect at bottom
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.clear)
                                        .background(.regularMaterial)
                                        .mask(
                                            LinearGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: .clear, location: 0.0),
                                                    .init(color: .black.opacity(0.5), location: 0.5),
                                                    .init(color: .black, location: 0.8),
                                                    .init(color: .black, location: 1.0)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: heroHeight * 0.67)
                                }
                            }
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
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("At a glance")
                                    .appBody()
                                    .foregroundColor(.white)

                                LazyVGrid(columns: metaGridColumns, spacing: 12) {
                                    ForEach(metaCards) { card in
                                        EventMetaCard(data: card)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            if let tags = event.tags, !tags.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Tags")
                                        .appBody()
                                        .foregroundColor(.white)

                                    LazyVGrid(columns: tagColumns, spacing: 8) {
                                        ForEach(tags, id: \.self) { tag in
                                            EventTagChip(text: tag)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            if let description = event.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About")
                                        .appBody()
                                        .foregroundColor(.white)

                                    Text(description)
                                        .appBody()
                                        .foregroundColor(.gray)
                                        .lineSpacing(2)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 120)
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
                                .appBody()
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
    }
    
    private func checkUserTicketStatus() {
        guard let eventId = event.id else { return }
        
        eventViewModel.checkUserTicketStatus(for: eventId) { hasTicket in
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

// MARK: - Event Meta Views
private struct EventMetaCardData: Identifiable {
    var id: String { title }
    let title: String
    let primaryText: String
    let secondaryText: String?
}

private struct EventMetaCard: View {
    let data: EventMetaCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title.uppercased())
                .appCaption()
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.2)

            Text(data.primaryText)
                .appSectionHeader()
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let secondary = data.secondaryText, !secondary.isEmpty {
                Text(secondary)
                    .appSecondary()
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct EventTagChip: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .appCaption()
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }
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
