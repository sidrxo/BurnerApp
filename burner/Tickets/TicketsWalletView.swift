import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import Combine

struct TicketsWalletView: View {
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    
    @State private var selectedTicketId: String?
    @State private var showingFullScreen = false
    @State private var selectedTicketForQR: TicketWithEventData?
    
    private var ticketsWithEvents: [TicketWithEventData] {
        var result: [TicketWithEventData] = []
        for ticket in ticketsViewModel.tickets {
            if let event = eventViewModel.events.first(where: { $0.id == ticket.eventId }) {
                result.append(TicketWithEventData(ticket: ticket, event: event))
            } else {
                let placeholderEvent = Event(
                    name: ticket.eventName,
                    venue: ticket.venue,
                    startTime: ticket.startTime,
                    price: ticket.totalPrice,
                    maxTickets: 100,
                    ticketsSold: 0,
                    imageUrl: "",
                    isFeatured: false,
                    description: nil
                )
                var eventWithId = placeholderEvent
                eventWithId.id = ticket.eventId
                result.append(TicketWithEventData(ticket: ticket, event: eventWithId))
            }
        }
        return result
    }
    
    private func isEventPast(_ event: Event) -> Bool {
        guard let startTime = event.startTime else { return true }
        let calendar = Calendar.current
        let nextDayEnd = calendar.dateInterval(of: .day, for: startTime)?.end ?? startTime
        let nextDay6AM = calendar.date(byAdding: .hour, value: 6, to: nextDayEnd) ?? startTime
        return Date() > nextDay6AM
    }
    
    private var filteredTickets: [TicketWithEventData] {
        return ticketsWithEvents
            .filter { !isEventPast($0.event) }
            .sorted {
                ($0.event.startTime ?? Date.distantFuture) < ($1.event.startTime ?? Date.distantFuture)
            }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !ticketsViewModel.tickets.isEmpty || ticketsViewModel.isLoading {
                        HeaderSection(title: "My Tickets")
                    }
                    
                    if ticketsViewModel.isLoading && ticketsViewModel.tickets.isEmpty {
                        loadingView
                    } else if ticketsViewModel.tickets.isEmpty {
                        emptyStateView
                    } else {
                        walletStackView
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                ticketsViewModel.fetchUserTickets()
                eventViewModel.fetchEvents()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showingFullScreen) {
            if let ticket = selectedTicketForQR {
                FullScreenQRCodeView(
                    ticketWithEvent: ticket,
                    qrCodeData: ticket.ticket.qrCode ?? "INVALID_TICKET"
                )
            }
        }
    }
    
    // MARK: - Wallet Stack View
    private var walletStackView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(filteredTickets.enumerated()), id: \.element.id) { index, ticketWithEvent in
                        let isSelected = selectedTicketId == ticketWithEvent.id
                        let isPast = isEventPast(ticketWithEvent.event)
                        
                        WalletTicketCard(
                            ticketWithEvent: ticketWithEvent,
                            isSelected: isSelected,
                            isPast: isPast,
                            index: index,
                            totalCards: filteredTickets.count,
                            onTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    if selectedTicketId == ticketWithEvent.id {
                                        selectedTicketId = nil
                                    } else {
                                        selectedTicketId = ticketWithEvent.id
                                    }
                                }
                            },
                            onQRTap: {
                                if appState.burnerManager.isSetupValid {
                                    selectedTicketForQR = ticketWithEvent
                                    showingFullScreen = true
                                }
                            },
                            onDelete: isPast ? {
                                softDeleteTicket(ticketWithEvent.ticket)
                            } : nil
                        )
                        .environmentObject(appState)
                        .offset(y: calculateOffset(for: index))
                        .zIndex(Double(index))
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 200)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private func calculateOffset(for index: Int) -> CGFloat {
        let peekAmount: CGFloat = -400
        let revealAmount: CGFloat = 400 // Change this to control how far cards move down
        
        guard let selectedId = selectedTicketId,
              let selectedIndex = filteredTickets.firstIndex(where: { $0.id == selectedId }) else {
            // No card selected - normal stacked position
            return CGFloat(index) * peekAmount
        }
        
        if index <= selectedIndex {
            // Cards at or before selected card stay in stacked position
            return CGFloat(index) * peekAmount
        } else {
            // Cards after selected card move down to reveal the selected card
            return CGFloat(selectedIndex) * peekAmount + revealAmount + CGFloat(index - selectedIndex) * peekAmount
        }
    }
    
    // MARK: - Supporting Views
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "ticket")
                .font(.appLargeIcon)
                .foregroundColor(.gray)
            VStack(spacing: 8) {
                Text("No Tickets Yet")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Text("Your purchased tickets will appear here")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button {
                selectedTab = 0
            } label: {
                Text("Browse Events")
                    .appBody()
                    .foregroundColor(.black)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading your tickets...")
                .appBody()
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func softDeleteTicket(_ ticket: Ticket) {
        guard let ticketId = ticket.id else { return }
        
        let db = Firestore.firestore()
        db.collection("tickets").document(ticketId).updateData([
            "deleted": true,
            "deletedAt": FieldValue.serverTimestamp()
        ]) { error in
            if error == nil {
                Task { @MainActor in
                    selectedTicketId = nil
                    ticketsViewModel.fetchUserTickets()
                }
            }
        }
    }
}

// MARK: - Wallet Ticket Card
struct WalletTicketCard: View {
    let ticketWithEvent: TicketWithEventData
    let isSelected: Bool
    let isPast: Bool
    let index: Int
    let totalCards: Int
    let onTap: () -> Void
    let onQRTap: () -> Void
    let onDelete: (() -> Void)?
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Top section with event info
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ticketWithEvent.event.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.black.opacity(0.5))
                            Text(ticketWithEvent.event.venue)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(formatDate(ticketWithEvent.event.startTime ?? Date()))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text(formatTime(ticketWithEvent.event.startTime ?? Date()))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                .padding(24)
                
                // Divider with decorative dots
                HStack(spacing: 12) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                // Bottom section with ticket info
                HStack {
                    Text(ticketWithEvent.ticket.ticketNumber ?? "—")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.5))
                        .tracking(1)
                    
                    Spacer()
                    
                    Text(ticketWithEvent.ticket.status.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                        .tracking(1.5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Subtle separator
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.05),
                                Color.black.opacity(0.02),
                                Color.black.opacity(0.05)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                
                // Purchase details
                VStack(spacing: 16) {
                    detailRow(
                        icon: "calendar",
                        label: "Purchase Date",
                        value: formatFullDate(ticketWithEvent.ticket.purchaseDate)
                    )
                    
                    detailRow(
                        icon: "creditcard",
                        label: "Price Paid",
                        value: String(format: "£%.2f", ticketWithEvent.ticket.totalPrice)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // QR Code section
                if appState.burnerManager.isSetupValid {
                    Button(action: onQRTap) {
                        VStack(spacing: 16) {
                            ZStack {
                                // White background for QR code
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .frame(width: 200, height: 200)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                
                                QRCodeView(
                                    data: ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET",
                                    size: 170,
                                    backgroundColor: .white,
                                    foregroundColor: .black
                                )
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("TAP TO SCAN")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(2)
                            }
                            .foregroundColor(.black.opacity(0.4))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.03))
                                .frame(width: 200, height: 200)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.black.opacity(0.2))
                                
                                VStack(spacing: 6) {
                                    Text("QR Code Hidden")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.6))
                                    
                                    Text("Enable in Settings")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.black.opacity(0.4))
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 28)
            }
            .background(
                ZStack {
                    // Subtle gradient for depth
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color(white: 0.98)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle pattern overlay based on index for differentiation
                    Color.white.opacity(Double(index % 3) * 0.02)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.08),
                                Color.black.opacity(0.04)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.12), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 8 : 4)
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            .scaleEffect(isSelected ? 1.0 : 1.0)
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.4))
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
