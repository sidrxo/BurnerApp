import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    @State private var searchText = ""
    @State private var selectedEvent: Event? = nil

    // MARK: - Featured Events (Randomized by Day)
    var featuredEvents: [Event] {
        let featured = eventViewModel.events.filter { $0.isFeatured }
        
        // Seed random with current day for consistent daily rotation
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        
        var rng = SeededRandomNumberGenerator(seed: UInt64(dayOfYear))
        return featured.shuffled(using: &rng)
    }
    
    var featuredEvent: Event? {
        featuredEvents.first
    }
    
    var secondFeaturedEvent: Event? {
        featuredEvents.count > 1 ? featuredEvents[1] : nil
    }
    
    // MARK: - Popular Events (Sorted by Ticket Sell-Through %)
    var popularEvents: [Event] {
        eventViewModel.events
            .filter { !$0.isFeatured && $0.date > Date() }
            .sorted { event1, event2 in
                let sellThrough1 = Double(event1.ticketsSold) / Double(max(event1.maxTickets, 1))
                let sellThrough2 = Double(event2.ticketsSold) / Double(max(event2.maxTickets, 1))
                return sellThrough1 > sellThrough2
            }
            .prefix(5)  // ✅ CHANGED FROM 4 TO 5
            .map { $0 }
    }
    
    // MARK: - Upcoming Events (Sorted by Date - Soonest First)
    var upcomingEvents: [Event] {
        eventViewModel.events
            .filter { $0.date > Date() && !$0.isFeatured }
            .sorted { $0.date < $1.date }
            .prefix(5)  // ✅ CHANGED FROM 4 TO 5
            .map { $0 }
    }
    
    // MARK: - All Events (Sorted by Date)
    var allEvents: [Event] {
        eventViewModel.events
            .filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
            .prefix(6)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HeaderSection(title: "Explore")
                    
                    if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                        loadingView
                    } else {
                        contentView
                    }
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
            .background(Color.black)
            .refreshable {
                eventViewModel.fetchEvents()
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            // Primary Featured Event
            if let featured = featuredEvent {
                NavigationLink(value: featured) {
                    FeaturedHeroCard(event: featured, bookmarkManager: bookmarkManager)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Popular Section (by ticket sales %)
            if !popularEvents.isEmpty {
                EventSection(
                    title: "Popular",
                    events: popularEvents,
                    bookmarkManager: bookmarkManager
                )
            }
            
            // Upcoming Section (by date proximity)
            if !upcomingEvents.isEmpty {
                EventSection(
                    title: "Upcoming",
                    events: upcomingEvents,
                    bookmarkManager: bookmarkManager
                )
            }
            
            // Secondary Featured Event
            if let secondFeatured = secondFeaturedEvent {
                NavigationLink(value: secondFeatured) {
                    FeaturedHeroCard(event: secondFeatured, bookmarkManager: bookmarkManager)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // All Events Section
            if !allEvents.isEmpty {
                EventSection(
                    title: "All Events",
                    events: allEvents,
                    bookmarkManager: bookmarkManager
                )
            }
        }
    }
}

// MARK: - Seeded Random Number Generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Reusable Event Section Component
struct EventSection: View {
    let title: String
    let events: [Event]
    let bookmarkManager: BookmarkManager
    let showViewAllButton: Bool
    let onViewAllTapped: (() -> Void)?
    
    init(
        title: String,
        events: [Event],
        bookmarkManager: BookmarkManager,
        showViewAllButton: Bool = true,
        onViewAllTapped: (() -> Void)? = nil
    ) {
        self.title = title
        self.events = events
        self.bookmarkManager = bookmarkManager
        self.showViewAllButton = showViewAllButton
        self.onViewAllTapped = onViewAllTapped
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(title)
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Spacer()
                
                if showViewAllButton {
                    Button(action: {
                        onViewAllTapped?()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.appIcon)
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Event List - ✅ CHANGED TO SPACING: 0 FOR TIGHTER ROWS
            LazyVStack(spacing: 0) {
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        UnifiedEventRow(
                            event: event,
                            bookmarkManager: bookmarkManager
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState().eventViewModel)
            .environmentObject(AppState().bookmarkManager)
            .preferredColorScheme(.dark)
    }
}

// MARK: - Event Equatable & Hashable (for NavigationLink value)
extension Event: Hashable {
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
