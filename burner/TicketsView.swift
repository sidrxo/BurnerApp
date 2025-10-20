import SwiftUI
import Kingfisher
import FirebaseAuth
import Combine

struct TicketsView: View {
    // ✅ Use shared ViewModels from environment
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    
    // Add binding for selected tab
    @Binding var selectedTab: Int
    
    @State private var searchText = ""
    @State private var selectedFilter: TicketsFilter = .upcoming

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
                    date: ticket.eventDate,
                    price: ticket.ticketPrice,
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
    private func isEventPast(_ eventDate: Date) -> Bool {
        let calendar = Calendar.current
        let nextDay6AM = calendar.dateInterval(of: .day, for: eventDate)?.end ?? eventDate
        let nextDay6AMDate = calendar.date(byAdding: .hour, value: 6, to: nextDay6AM) ?? eventDate
        return Date() > nextDay6AMDate
    }

    private var filteredTickets: [TicketWithEventData] {
        var result = ticketsWithEvents
        switch selectedFilter {
        case .upcoming:
            result = result.filter { !isEventPast($0.event.eventDate) }
        case .past:
            result = result.filter { isEventPast($0.event.eventDate) }
        }
        if !searchText.isEmpty {
            result = result.filter { ticketWithEvent in
                ticketWithEvent.event.name.localizedCaseInsensitiveContains(searchText) ||
                ticketWithEvent.event.venue.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { $0.event.eventDate > $1.event.eventDate }
    }

    private var upcomingTickets: [TicketWithEventData] {
        filteredTickets.filter { !isEventPast($0.event.eventDate) }
    }

    private var pastTickets: [TicketWithEventData] {
        filteredTickets.filter { isEventPast($0.event.eventDate) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !ticketsViewModel.tickets.isEmpty || ticketsViewModel.isLoading {
                    HeaderSection(title: "My Tickets")
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
            .refreshable {
                ticketsViewModel.fetchUserTickets()
                eventViewModel.fetchEvents()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

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
            }
            Button {
                // Navigate to Home tab (index 0)
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
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 20)
        }
        .background(Color.black)
    }

    // MARK: - Filters Section
    private var filtersSection: some View {
        HStack(spacing: 12) {
            ForEach(TicketsFilter.allCases, id: \.self) { filter in
                FilterButton(title: filter.displayName, isSelected: selectedFilter == filter) {
                    withAnimation(.easeInOut(duration: 0.2)) {
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
            Image(systemName: "magnifyingglass")
                .font(.appLargeIcon)
                .foregroundColor(.gray)
            VStack(spacing: 8) {
                Text("No Results Found")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Text("Try adjusting your search terms")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
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
                        ForEach(upcomingTickets, id: \.ticket.id) { ticketWithEvent in
                            NavigationLink(
                                destination: TicketDetailView(ticketWithEvent: ticketWithEvent)
                            ) {
                                UnifiedEventRow(
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
                            ForEach(pastTickets, id: \.ticket.id) { ticketWithEvent in
                                NavigationLink(
                                    destination: TicketDetailView(ticketWithEvent: ticketWithEvent)
                                ) {
                                    UnifiedEventRow(
                                        ticketWithEvent: ticketWithEvent,
                                        isPast: true,
                                        onCancel: {
                                            // Past tickets can't be cancelled
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
    TicketsView(selectedTab: .constant(2))
        .environmentObject(AppState().ticketsViewModel)
        .environmentObject(AppState().eventViewModel)
        .preferredColorScheme(.dark)
}
