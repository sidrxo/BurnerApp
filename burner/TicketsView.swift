import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import Combine

struct TicketsView: View {
    // ✅ Use shared ViewModels from environment
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.settingsTransitionNamespace) private var settingsTransition

    @State private var searchText = ""
    @State private var selectedFilter: TicketsFilter = .upcoming
    @FocusState private var isSearchFocused: Bool
    
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
    
    // Helper function to determine if an event should be considered "past"
    private func isEventPast(_ event: Event) -> Bool {
        guard let startTime = event.startTime else { return true }
        let calendar = Calendar.current
        let nextDayEnd = calendar.dateInterval(of: .day, for: startTime)?.end ?? startTime
        let nextDay6AM = calendar.date(byAdding: .hour, value: 6, to: nextDayEnd) ?? startTime
        return Date() > nextDay6AM
    }
    
    private var filteredTickets: [TicketWithEventData] {
        var result = ticketsWithEvents
        switch selectedFilter {
        case .upcoming:
            result = result.filter { !isEventPast($0.event) }
        case .past:
            result = result.filter { isEventPast($0.event) }
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
        filteredTickets.filter { !isEventPast($0.event) }
    }
    
    private var pastTickets: [TicketWithEventData] {
        filteredTickets.filter { ticketWithEvent in
            isEventPast(ticketWithEvent.event) &&
            ticketWithEvent.ticket.status != "cancelled"
        }
    }
    
    var body: some View {
        // ❌ Removed NavigationView - now handled by MainTabView
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
            Spacer()
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    coordinator.ticketsPath.append(NavigationDestination.settings)
                }
            }) {
                Group {
                    if let namespace = settingsTransition {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .matchedGeometryEffect(id: "settingsGear", in: namespace)
                    } else {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    private var emptyStateView: some View {
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
                    Text(AppConstants.EmptyState.meetMeInTheMoment)
                        .appSectionHeader()
                        .foregroundColor(.white)
                    Text(AppConstants.EmptyState.noTickets)
                        .appBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                BurnerButton("BROWSE EVENTS", style: .primary, maxWidth: 200) {
                    coordinator.selectTab(.home)
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
            LazyVStack(spacing: 20) {
                // Upcoming Events Section
                if !upcomingTickets.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(upcomingTickets, id: \.id) { ticketWithEvent in
                            NavigationLink(
                                destination: TicketDetailView(ticketWithEvent: ticketWithEvent)
                            ) {
                                EventRow(
                                    ticketWithEvent: ticketWithEvent,
                                    isPast: false,
                                    onCancel: {
                                        // Handle ticket cancellation
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Past Events Section
                if !pastTickets.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        LazyVStack(spacing: 12) {
                            ForEach(pastTickets, id: \.id) { ticketWithEvent in
                                NavigationLink(
                                    destination: TicketDetailView(ticketWithEvent: ticketWithEvent)
                                ) {
                                    EventRow(
                                        ticketWithEvent: ticketWithEvent,
                                        isPast: true,
                                        onCancel: {
                                            // No longer used
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            ticketsViewModel.fetchUserTickets()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.black)
    }
}

// MARK: - Supporting Types
enum TicketsFilter: CaseIterable {
    case upcoming, past
    var displayName: String {
        switch self {
        case .upcoming: return "UPCOMING"
        case .past: return "PAST"
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
