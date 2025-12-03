import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Ticket Grid Item
struct TicketGridItem: View {
    let ticketWithEvent: TicketWithEventData

    var body: some View {
        VStack(spacing: 0) {
            // Image section
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
            
            // Event info below image
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
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading) // ✅ Fixed minimum height for the entire info section
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
    // ✅ Use shared ViewModels from environment
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator

    @State private var searchText = ""
    @State private var selectedFilter: TicketsFilter = .upcoming
    @State private var selectedTicket: TicketWithEventData?
    @FocusState private var isSearchFocused: Bool

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
                // Create a placeholder event if event data is missing
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

    private var filteredTickets: [TicketWithEventData] {
        var result = ticketsWithEvents
        switch selectedFilter {
        case .upcoming:
            result = result.filter { !$0.event.isPast }
        case .past:
            result = result.filter { $0.event.isPast }
        }
        if !searchText.isEmpty {
            result = result.filter { ticketWithEvent in
                ticketWithEvent.event.name.localizedCaseInsensitiveContains(searchText) ||
                ticketWithEvent.event.venue.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted {
            ($0.event.startTime ?? Date.distantFuture) < ($1.event.startTime ?? Date.distantFuture)
        }
    }

    private var upcomingTickets: [TicketWithEventData] {
        filteredTickets.filter { !$0.event.isPast }
    }

    private var pastTickets: [TicketWithEventData] {
        filteredTickets.filter { ticketWithEvent in
            ticketWithEvent.event.isPast &&
            ticketWithEvent.ticket.status != "cancelled"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header with settings gear
            ticketsHeader

            if !ticketsViewModel.tickets.isEmpty || ticketsViewModel.isLoading {
                searchSection
                filtersSection
            }

            if ticketsViewModel.isLoading && ticketsViewModel.tickets.isEmpty {
                loadingView
            } else if ticketsViewModel.tickets.isEmpty {
                emptyStateView
            } else if filteredTickets.isEmpty {
                emptyFilteredView
            } else {
                ticketsList
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }

    // MARK: - Tickets Header with Settings Gear
    private var ticketsHeader: some View {
        HStack {
            Text("Tickets")
                .appPageHeader()
                .foregroundColor(.white)
                .padding(.bottom, 2)

            Spacer()
            Button(action: {
                if Auth.auth().currentUser == nil {
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
            if Auth.auth().currentUser == nil {
                signedOutEmptyState
            } else {
                noTicketsEmptyState
            }
        }
    }
    
    private var signedOutEmptyState: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // ✅ Fixed-height frame for image
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140) // fixed height
                    .frame(maxWidth: .infinity) // center horizontally
                    .padding(.bottom, 30)
                
                VStack(spacing: 8) {
                    TightHeaderText("WHERE WILL", "YOU GO?", alignment: .center)
                        .frame(maxWidth: .infinity)
                    Text("Be part of the change.")
                        .appCard()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                BurnerButton("SIGN UP / IN", style: .primary, maxWidth: 180) {
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
                // ✅ Fixed-height frame for image
                Image("ticket")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140) // fixed height
                    .frame(maxWidth: .infinity) // center horizontally
                    .padding(.bottom, 30)
                
                VStack(spacing: 8) {
                    TightHeaderText("NO TICKETS", "YET", alignment: .center)
                        .frame(maxWidth: .infinity)
                    Text("Your next experience is waiting.")
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
    
    // MARK: - Search Bar
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .appBody()
                    .foregroundColor(.gray)
                
                TextField("Search tickets", text: $searchText)
                    .appBody()
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isSearchFocused)
                
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.appIcon)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 22/255, green: 22/255, blue: 23/255))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = true
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        HStack(spacing: 12) {
            Spacer()

            ForEach(TicketsFilter.allCases, id: \.self) { filter in
                FilterButton(title: filter.displayName, isSelected: selectedFilter == filter) {
                    // Haptic feedback for filter change
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: AppConstants.standardAnimationDuration)) {
                        selectedFilter = filter
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
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
    
    private var emptyFilteredView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("No Results Found")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Text("Try adjusting your search terms")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .padding(.bottom, 16)
    }
    
    private var ticketsList: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredTickets, id: \.id) { ticketWithEvent in
                    Button(action: {
                        selectedTicket = ticketWithEvent
                    }) {
                        TicketGridItem(ticketWithEvent: ticketWithEvent)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            ticketsViewModel.fetchUserTickets()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.black)
        .sheet(item: $selectedTicket) { ticketWithEvent in
            TicketDetailView(ticketWithEvent: ticketWithEvent)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled(false)
        }
    }
}

// MARK: - Supporting Types
enum TicketsFilter: CaseIterable {
    case upcoming, past
    var displayName: String {
        switch self {
        case .upcoming: return "NEXT UP"
        case .past: return "HISTORY"
        }
    }
    static var allCases: [TicketsFilter] { [.upcoming, .past] }
}



#Preview {
    TicketsView()
        .environmentObject(AppState().ticketsViewModel)
        .environmentObject(AppState().eventViewModel)
        .environmentObject(NavigationCoordinator())
        .preferredColorScheme(.dark)
}
