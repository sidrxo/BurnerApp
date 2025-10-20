import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    @State private var searchText = ""
    @State private var selectedEvent: Event? = nil
    
    // MARK: - Define Your Genres (Configure these based on your events)
    private let displayGenres = ["Techno", "House", "Drum & Bass", "Trance", "Hip Hop"]

    // MARK: - Featured Events (Randomized by Day)
    var featuredEvents: [Event] {
        let featured = eventViewModel.events.filter { $0.isFeatured }
        
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
            .filter { !$0.isFeatured && $0.eventDate > Date() }
            .sorted { event1, event2 in
                let sellThrough1 = Double(event1.ticketsSold) / Double(max(event1.maxTickets, 1))
                let sellThrough2 = Double(event2.ticketsSold) / Double(max(event2.maxTickets, 1))
                return sellThrough1 > sellThrough2
            }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - This Week Events (Current Week Ending Sunday)
    var thisWeekEvents: [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        var weekStartComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        weekStartComponents.weekday = 1
        guard let weekStart = calendar.date(from: weekStartComponents) else {
            return []
        }
        
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        
        let popularEventIds = Set(popularEvents.compactMap { $0.id })
        
        return eventViewModel.events
            .filter {
                !$0.isFeatured &&
                $0.eventDate >= now &&
                $0.eventDate < weekEnd &&
                !popularEventIds.contains($0.id ?? "")
            }
            .sorted { $0.eventDate < $1.eventDate }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Genre-Based Events (NEW)
    func eventsForGenre(_ genre: String, excludingIds: Set<String>) -> [Event] {
        eventViewModel.events
            .filter {
                !$0.isFeatured &&
                $0.eventDate > Date() &&
                !excludingIds.contains($0.id ?? "") &&
                ($0.tags?.contains { $0.localizedCaseInsensitiveCompare(genre) == .orderedSame } ?? false)
            }
            .sorted { $0.eventDate < $1.eventDate }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - All Events (Sorted by Date)
    var allEvents: [Event] {
        let popularEventIds = Set(popularEvents.compactMap { $0.id })
        let thisWeekEventIds = Set(thisWeekEvents.compactMap { $0.id })
        
        // Also exclude genre events
        var genreEventIds = Set<String>()
        for genre in displayGenres {
            let genreEvents = eventsForGenre(genre, excludingIds: popularEventIds.union(thisWeekEventIds))
            genreEventIds.formUnion(Set(genreEvents.compactMap { $0.id }))
        }
        
        return eventViewModel.events
            .filter {
                $0.eventDate > Date() &&
                !popularEventIds.contains($0.id ?? "") &&
                !thisWeekEventIds.contains($0.id ?? "") &&
                !genreEventIds.contains($0.id ?? "")
            }
            .sorted { $0.eventDate < $1.eventDate }
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
            
            // Popular Section
            if !popularEvents.isEmpty {
                EventSection(
                    title: "Popular",
                    events: popularEvents,
                    bookmarkManager: bookmarkManager
                )
            }
            
            // This Week Section
            if !thisWeekEvents.isEmpty {
                EventSection(
                    title: "This Week",
                    events: thisWeekEvents,
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
            
            // MARK: - Genre Sections (NEW)
            genreSections
            
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
    
    // MARK: - Genre Sections View (NEW)
    private var genreSections: some View {
        let popularEventIds = Set(popularEvents.compactMap { $0.id })
        let thisWeekEventIds = Set(thisWeekEvents.compactMap { $0.id })
        let excludedIds = popularEventIds.union(thisWeekEventIds)
        
        return ForEach(displayGenres, id: \.self) { genre in
            let genreEvents = eventsForGenre(genre, excludingIds: excludedIds)
            
            if !genreEvents.isEmpty {
                EventSection(
                    title: genre,
                    events: genreEvents,
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
            
            // Event List
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

// MARK: - Event Equatable & Hashable
extension Event: Hashable {
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
