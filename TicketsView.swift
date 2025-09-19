import SwiftUI
import Kingfisher
import FirebaseFirestore
import FirebaseAuth
import Combine

struct TicketsView: View {
    @StateObject private var viewModel = EventViewModel()
    @State private var tickets: [Ticket] = []
    @State private var isLoadingTickets = false
    @State private var searchText = ""
    @State private var selectedFilter: TicketsFilter = .upcoming // default to upcoming
    @State private var isPastEventsExpanded = false

    private let db = Firestore.firestore()

    private var ticketsWithEvents: [TicketWithEventData] {
        var result: [TicketWithEventData] = []
        for ticket in tickets {
            if let event = viewModel.events.first(where: { $0.id == ticket.eventId }) {
                result.append(TicketWithEventData(ticket: ticket, event: event))
            } else {
                // Create a placeholder event if event data is missing
                let placeholderEvent = Event(
                    name: ticket.eventName,
                    venue: ticket.venue,
                    date: ticket.eventDate,
                    price: ticket.pricePerTicket,
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
            result = result.filter { $0.event.date > Date() }
        case .past:
            result = result.filter { $0.event.date <= Date() }
        }
        if !searchText.isEmpty {
            result = result.filter { ticketWithEvent in
                ticketWithEvent.event.name.localizedCaseInsensitiveContains(searchText) ||
                ticketWithEvent.event.venue.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { $0.event.date > $1.event.date }
    }

    private var upcomingTickets: [TicketWithEventData] {
        filteredTickets.filter { $0.event.date > Date() && $0.ticket.status == "confirmed" }
    }

    private var pastTickets: [TicketWithEventData] {
        filteredTickets.filter { $0.event.date <= Date() }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchSection
                filtersSection
                if isLoadingTickets || viewModel.isLoading {
                    loadingView
                } else if tickets.isEmpty {
                    emptyStateView
                } else if filteredTickets.isEmpty {
                    emptyFilteredView
                } else {
                    ticketsList
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchEvents()
                fetchUserTicketsDirectly()
            }
            .refreshable {
                viewModel.fetchEvents()
                fetchUserTicketsDirectly()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - ExploreView-style Search Bar
    private var searchSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .appFont(size: 16, weight: .medium)
                    .foregroundColor(.gray)

                TextField("Search for an event or venue", text: $searchText)
                    .appFont(size: 16)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
        .background(Color.black)
    }

    // MARK: - ExploreView-style Filters Section
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

    // MARK: - Direct Firestore Query
    private func fetchUserTicketsDirectly() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user")
            return
        }
        isLoadingTickets = true
        db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .order(by: "purchaseDate", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    isLoadingTickets = false
                    if let error = error {
                        print("❌ Error fetching tickets: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        tickets = []
                        return
                    }
                    tickets = documents.compactMap { doc in
                        do {
                            var ticket = try doc.data(as: Ticket.self)
                            ticket.id = doc.documentID
                            return ticket
                        } catch {
                            return nil
                        }
                    }
                }
            }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading your tickets...")
                .appFont(size: 16)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "ticket")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            VStack(spacing: 8) {
                Text("No Tickets Yet")
                    .appFont(size: 22, weight: .semibold)
                    .foregroundColor(.white)
                Text("Your purchased tickets will appear here")
                    .appFont(size: 16)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            Button("Browse Events") {
                // Navigation to events
            }
            .appFont(size: 17, weight: .semibold)
            .foregroundColor(.black)
            .frame(maxWidth: 200)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .offset(y: -100)
    }

    private var emptyFilteredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            VStack(spacing: 8) {
                Text("No Results Found")
                    .appFont(size: 18, weight: .semibold)
                    .foregroundColor(.white)
                Text("Try adjusting your search terms")
                    .appFont(size: 16)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var ticketsList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Upcoming Events Section (no header)
                if !upcomingTickets.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(upcomingTickets, id: \.ticket.id) { ticketWithEvent in
                            NavigationLink(
                                destination: TicketDetailView(ticketWithEvent: ticketWithEvent)
                            ) {
                                TicketRowView(
                                    ticketWithEvent: ticketWithEvent,
                                    isPast: false,
                                    onCancel: { }
                                )
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                // Past Events Section - Expandable
                if !pastTickets.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPastEventsExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("Past Events")
                                    .appFont(size: 24, weight: .bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(pastTickets.count)")
                                    .appFont(size: 16)
                                    .foregroundColor(.gray)
                                Image(systemName: isPastEventsExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            .contentShape(Rectangle())
                        }
                        if isPastEventsExpanded {
                            LazyVStack(spacing: 12) {
                                ForEach(pastTickets, id: \.ticket.id) { ticketWithEvent in
                                    NavigationLink(
                                        destination: TicketDetailView(ticketWithEvent: ticketWithEvent)
                                    ) {
                                        TicketRowView(
                                            ticketWithEvent: ticketWithEvent,
                                            isPast: true,
                                            onCancel: { }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
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
struct TicketWithEventData: Codable, Identifiable {
    let ticket: Ticket
    let event: Event
    var id: String {
        ticket.id ?? UUID().uuidString
    }
}

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
        .preferredColorScheme(.dark)
}
