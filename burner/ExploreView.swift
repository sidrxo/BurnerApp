import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var selectedEvent: Event? = nil
    @State private var navigationPath = NavigationPath()
    @State private var deepLinkEventId: String?
    
    // MARK: - Define Your Genres
    private let displayGenres = ["Techno", "House", "Drum & Bass", "Trance", "Hip Hop"]

    // MARK: - Featured Events
    var featuredEvents: [Event] {
        let featured = eventViewModel.events.filter { $0.isFeatured }
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        var rng = SeededRandomNumberGenerator(seed: UInt64(dayOfYear))
        return featured.shuffled(using: &rng)
    }
    
    // MARK: - This Week Events
    var thisWeekEvents: [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfToday = calendar.startOfDay(for: now) as Date?,
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfToday) else {
            return []
        }
        
        return eventViewModel.events
            .filter { event in
                guard let startTime = event.startTime else { return false }
                return !event.isFeatured &&
                       startTime >= now &&
                       startTime < endOfWeek
            }
            .sorted { event1, event2 in
                (event1.startTime ?? Date.distantPast) < (event2.startTime ?? Date.distantPast)
            }
    }
    
    var thisWeekEventsPreview: [Event] {
        Array(thisWeekEvents.prefix(5))
    }
    
    // MARK: - Popular Events
    var popularEvents: [Event] {
        let thisWeekEventIds = Set(thisWeekEvents.compactMap { $0.id })
        
        return eventViewModel.events
            .filter { event in
                guard let startTime = event.startTime else { return false }
                return !event.isFeatured &&
                       startTime > Date() &&
                       !thisWeekEventIds.contains(event.id ?? "")
            }
            .sorted { event1, event2 in
                let sellThrough1 = Double(event1.ticketsSold) / Double(max(event1.maxTickets, 1))
                let sellThrough2 = Double(event2.ticketsSold) / Double(max(event2.maxTickets, 1))
                return sellThrough1 > sellThrough2
            }
    }
    
    var popularEventsPreview: [Event] {
        Array(popularEvents.prefix(5))
    }
    
    // MARK: - Genre-Based Events
    func allEventsForGenre(_ genre: String) -> [Event] {
        eventViewModel.events
            .filter { event in
                guard let startTime = event.startTime else { return false }
                return !event.isFeatured &&
                       startTime > Date() &&
                       (event.tags?.contains { $0.localizedCaseInsensitiveCompare(genre) == .orderedSame } ?? false)
            }
            .sorted { event1, event2 in
                (event1.startTime ?? Date.distantPast) < (event2.startTime ?? Date.distantPast)
            }
    }
    
    func eventsForGenrePreview(_ genre: String) -> [Event] {
        Array(allEventsForGenre(genre).prefix(5))
    }
    
    // MARK: - All Events
    var allEvents: [Event] {
        eventViewModel.events
            .filter { event in
                guard let startTime = event.startTime else { return false }
                return startTime > Date()
            }
            .sorted { event1, event2 in
                (event1.startTime ?? Date.distantPast) < (event2.startTime ?? Date.distantPast)
            }
    }
    
    var allEventsPreview: [Event] {
        Array(allEvents.prefix(6))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .navigationDestination(for: String.self) { eventId in
                EventDetailDestination(eventId: eventId)
            }
            .navigationDestination(for: EventSectionDestination.self) { destination in
                FilteredEventsView(
                    title: destination.title,
                    events: destination.events
                )
            }
        }
        .onAppear {
            setupDeepLinkListener()
        }
        .onChange(of: deepLinkEventId) { oldValue, newValue in
            if let eventId = newValue {
                print("🎯 HomeView: Navigating to event \(eventId)")
                navigationPath.append(eventId)
                deepLinkEventId = nil
            }
        }
    }
    
    // MARK: - Deep Link Listener
    private func setupDeepLinkListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToEvent"),
            object: nil,
            queue: .main
        ) { notification in
            if let eventId = notification.object as? String {
                print("📱 HomeView: Received deep link notification for event \(eventId)")
                self.deepLinkEventId = eventId
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
            // Featured Hero Card
            if let featured = featuredEvents.first {
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
                    events: popularEventsPreview,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: false,
                    onViewAllTapped: {
                        navigationPath.append(EventSectionDestination(
                            title: "Popular",
                            events: popularEvents
                        ))
                    }
                )
            }
            
            // This Week Section
            if !thisWeekEvents.isEmpty {
                EventSection(
                    title: "This Week",
                    events: thisWeekEventsPreview,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: false,
                    onViewAllTapped: {
                        navigationPath.append(EventSectionDestination(
                            title: "This Week",
                            events: thisWeekEvents
                        ))
                    }
                )
            }
            
            // Genre Sections
            genreSectionsWithFeaturedCards
            
            // All Events Section
            if !allEvents.isEmpty {
                EventSection(
                    title: "All Events",
                    events: allEventsPreview,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: allEvents.count > 6,
                    onViewAllTapped: {
                        navigationPath.append(EventSectionDestination(
                            title: "All Events",
                            events: allEvents
                        ))
                    }
                )
            }
        }
    }
    
    private var genreSectionsWithFeaturedCards: some View {
        let genresWithEvents = displayGenres.filter { genre in
            !allEventsForGenre(genre).isEmpty
        }
        
        return ForEach(Array(genresWithEvents.enumerated()), id: \.offset) { index, genre in
            let genreEvents = allEventsForGenre(genre)
            let genrePreview = eventsForGenrePreview(genre)
            
            Group {
                if index % 2 == 0 {
                    let featuredIndex = 1 + (index / 2)
                    if featuredIndex < featuredEvents.count {
                        NavigationLink(value: featuredEvents[featuredIndex]) {
                            FeaturedHeroCard(event: featuredEvents[featuredIndex], bookmarkManager: bookmarkManager)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                EventSection(
                    title: genre,
                    events: genrePreview,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: true,
                    onViewAllTapped: {
                        navigationPath.append(EventSectionDestination(
                            title: genre,
                            events: genreEvents
                        ))
                    }
                )
            }
        }
    }
}

// MARK: - Event Section Destination
struct EventSectionDestination: Hashable {
    let title: String
    let events: [Event]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(events.compactMap { $0.id })
    }
    
    static func == (lhs: EventSectionDestination, rhs: EventSectionDestination) -> Bool {
        lhs.title == rhs.title &&
        lhs.events.compactMap { $0.id } == rhs.events.compactMap { $0.id }
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
                        EventRow(
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
