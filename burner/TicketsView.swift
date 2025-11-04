import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import Combine

struct TicketsView: View {
    // ✅ Use shared ViewModels from environment
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel

    // Add binding for selected tab
    @Binding var selectedTab: Int

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
        filteredTickets.filter { isEventPast($0.event) }
    }

    var body: some View {
        // ❌ Removed NavigationView - now handled by MainTabView
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

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("transparent")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .clipShape(Circle()) // 👈 makes it circular
            VStack(spacing: 8) {
                Text("MEET ME IN THE MOMENT")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Text("The best night of your life is one click away.")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button {
                // Navigate to Home tab (index 0)
                selectedTab = 0
            } label: {
                Text("BROWSE EVENTS")
                    .font(.appFont(size: 17))
                    .frame(maxWidth: 200)
                    .secondaryButtonStyle(
                        backgroundColor: .white,
                        foregroundColor: .black,
                        cornerRadius: 8
                    )
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
                            ForEach(pastTickets, id: \.id) { ticketWithEvent in
                                NavigationLink(
                                    destination: TicketDetailView(ticketWithEvent: ticketWithEvent)
                                ) {
                                    UnifiedEventRow(
                                        ticketWithEvent: ticketWithEvent,
                                        isPast: true,
                                        onCancel: {
                                            // No longer used
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        softDeleteTicket(ticketWithEvent.ticket)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.black)
    }

    // MARK: - Soft Delete Ticket
    private func softDeleteTicket(_ ticket: Ticket) {
        guard let ticketId = ticket.id else { return }

        let db = Firestore.firestore()
        db.collection("tickets").document(ticketId).updateData([
            "deleted": true,
            "deletedAt": FieldValue.serverTimestamp()
        ]) { error in
            // Refresh tickets to remove from view
            if error == nil {
                Task { @MainActor in
                    ticketsViewModel.fetchUserTickets()
                }
            }
        }
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
