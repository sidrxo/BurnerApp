import SwiftUI
import Kingfisher
import Combine
import Supabase

struct TicketGridItem: View {
    let ticketWithEvent: TicketWithEventData

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    if let url = URL(string: ticketWithEvent.event.imageUrl), !ticketWithEvent.event.imageUrl.isEmpty {
                        KFImage(url)
                            .placeholder {
                                ImagePlaceholder(size: geometry.size.width, cornerRadius: 12, iconSize: 24)
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .clipped()
                    } else {
                        ImagePlaceholder(size: geometry.size.width, cornerRadius: 12, iconSize: 24)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .aspectRatio(1, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ticketWithEvent.event.name)
                    .appBody()
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                if let startTime = ticketWithEvent.event.startTime {
                    Text(formatDate(startTime))
                        .appCaption()
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .padding(.top, 8)
            .padding(.horizontal, 4)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct TicketsView: View {
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState

    @State private var selectedFilter: Int = 0
    @State private var showTicketsAnimation = false
    @State private var showEmptyStateAnimation = false
    @State private var isLoadingTicketsAfterSignIn = false // State variable retained for manual loading control

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private var ticketsWithEvents: [TicketWithEventData] {
        var result: [TicketWithEventData] = []
        for ticket in ticketsViewModel.tickets {
            if let event = eventViewModel.events.first(where: { $0.id == ticket.eventId }) {
                result.append(TicketWithEventData(ticket: ticket, event: event))
            } else {
                // Creates a placeholder event using denormalized data from the ticket
                let placeholderEvent = Event(
                    name: ticket.eventName,
                    venue: ticket.venue,
                    startTime: ticket.startTime,
                    price: ticket.totalPrice ?? 0.0,
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

    private var filteredTickets: [TicketWithEventData] {
        var result = ticketsWithEvents
        
        switch selectedFilter {
        case 0:
            result = result.filter { !$0.event.isPast }
        case 1:
            result = result.filter { $0.event.isPast }
        default:
            result = result.filter { !$0.event.isPast }
        }
        
        return result.sorted {
            ($0.event.startTime ?? Date.distantFuture) < ($1.event.startTime ?? Date.distantFuture)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ticketsHeader

            if !ticketsViewModel.tickets.isEmpty || ticketsViewModel.isLoading {
                if hasPastTickets {
                    tabBarSection
                }
            }

            if isLoadingTicketsAfterSignIn {
                Color.black
            } else if ticketsViewModel.tickets.isEmpty {
                emptyStateView
                    .opacity(showEmptyStateAnimation ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showEmptyStateAnimation = true
                        }
                    }
                    .onDisappear {
                        showEmptyStateAnimation = false
                    }
            } else {
                ticketsList
                    .opacity(showTicketsAnimation ? 1 : 0)
                    .offset(y: showTicketsAnimation ? 0 : 30)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .onAppear {
            appState.syncBurnerModeAuthorization()
            
            // 1. Fetch tickets if the user is logged in
            if appState.authService.currentUser != nil {
                ticketsViewModel.fetchUserTickets()
            }

            // 2. Handle initial animation if data is already loaded
            if !ticketsViewModel.tickets.isEmpty {
                withAnimation(.easeOut(duration: 0.5)) {
                    showTicketsAnimation = true
                }
            }
        }
        .onDisappear {
            // Stop real-time connection when the view is not visible
            ticketsViewModel.cleanup()
        }
        
        // --- FIX: Simplify Sign-in/Sign-out Logic ---
        .onChange(of: appState.authService.currentUser) { _, newUser in
            if newUser != nil {
                // User just signed in: Start loading animation and fetch
                showTicketsAnimation = false
                isLoadingTicketsAfterSignIn = true
                ticketsViewModel.fetchUserTickets()
            } else {
                // User signed out: Stop observation and clear view
                showTicketsAnimation = false
                isLoadingTicketsAfterSignIn = false
                ticketsViewModel.cleanup()
            }
        }
        .onChange(of: ticketsViewModel.isLoading) { _, newValue in
            // Stop sign-in loading flag when the VM is no longer loading
            if isLoadingTicketsAfterSignIn && !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isLoadingTicketsAfterSignIn = false
                }
            }
        }
        .onChange(of: ticketsViewModel.tickets.count) { oldCount, newCount in
            // Re-trigger animation on data change (especially for real-time updates)
            if (oldCount == 0 && newCount > 0) || (oldCount > 0 && newCount == 0) {
                showTicketsAnimation = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showTicketsAnimation = true
                    }
                }
            }
        }
    }

    private var ticketsHeader: some View {
        HStack {
            Text("Tickets")
                .appPageHeader()
                .foregroundColor(.white)
                .padding(.bottom, 2)

            Spacer()
            Button(action: {
                if appState.authService.currentUser == nil {
                    coordinator.showSignIn()
                } else {
                    coordinator.ticketsPath.append(NavigationDestination.settings)
                }
            }) {
                ZStack {
                    Image("settings")
                        .appCard()
                        .frame(width: 38, height: 38)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 14)
        .padding(.bottom, 30)
    }
    
    private var emptyStateView: some View {
        Group {
            if appState.authService.currentUser == nil {
                signedOutEmptyState
            } else {
                noTicketsEmptyState
            }
        }
    }
    
    private var signedOutEmptyState: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                
                VStack(spacing: 8) {
                    TightHeaderText("WHERE WILL", "YOU GO?", alignment: .center)
                        .frame(maxWidth: .infinity)
                    Text("Sign in below to get started.")
                        .appCard()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                BurnerButton("SIGN UP/IN", style: .primary, maxWidth: 160) {
                    coordinator.showSignIn()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var noTicketsEmptyState: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Image("ticket")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                
                VStack(spacing: 8) {
                    TightHeaderText("EMPTY", "(FOR NOW?)", alignment: .center)
                        .frame(maxWidth: .infinity)
                    Text("Find something worth remembering.")
                        .appCard()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                BurnerButton("EXPLORE EVENTS", style: .primary, maxWidth: 200) {
                    coordinator.selectTab(.explore)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private var tabBarSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = 0
                    }
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                } label: {
                    Text("NEXT UP")
                        .appSecondary(weight: selectedFilter == 0 ? .bold : .medium)
                        .foregroundColor(selectedFilter == 0 ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedFilter = 1
                    }
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                } label: {
                    Text("HISTORY")
                        .appSecondary(weight: selectedFilter == 1 ? .bold : .medium)
                        .foregroundColor(selectedFilter == 1 ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(red: 38/255, green: 38/255, blue: 38/255))
                    .frame(height: 1)
                
                GeometryReader { geometry in
                    let tabWidth = geometry.size.width / 2
                    let indicatorWidth: CGFloat = selectedFilter == 0 ? 55 : 60
                    let xOffset = selectedFilter == 0
                        ? (tabWidth - indicatorWidth) / 2
                        : tabWidth + (tabWidth - indicatorWidth) / 2
                    
                    Rectangle()
                        .fill(.white)
                        .frame(width: indicatorWidth, height: 2)
                        .offset(x: xOffset, y: 1)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.black)
    }
    
    private var hasPastTickets: Bool {
        ticketsWithEvents.contains { $0.event.isPast }
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
        .background(Color.black)
    }
    
    private var ticketsList: some View {
        GeometryReader { geometry in
            let gridHeight = calculateGridHeight(availableWidth: geometry.size.width - 40)
            let needsScroll = gridHeight > geometry.size.height - 100
            
            if needsScroll {
                ScrollView {
                    ticketsGrid
                }
                .refreshable {
                    ticketsViewModel.fetchUserTickets()
                }
            } else {
                ticketsGrid
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color.black)
    }
    
    private var ticketsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredTickets, id: \.id) { ticketWithEvent in
                Button(action: {
                    coordinator.navigate(to: .ticketDetail(ticketWithEvent))
                }) {
                    TicketGridItem(ticketWithEvent: ticketWithEvent)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    
    private func calculateGridHeight(availableWidth: CGFloat) -> CGFloat {
        let itemWidth = (availableWidth - 24) / 3
        let itemHeight = itemWidth + 60 + 8 + 4
        let rows = ceil(Double(filteredTickets.count) / 3.0)
        let totalHeight = (itemHeight * CGFloat(rows)) + (12 * CGFloat(max(0, rows - 1))) + 100
        return totalHeight
    }
}
