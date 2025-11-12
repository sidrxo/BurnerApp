import SwiftUI
import Kingfisher
import CoreLocation
internal import FirebaseFirestoreInternal

struct ExploreView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var tagViewModel: TagViewModel
    @EnvironmentObject var userLocationManager: UserLocationManager

    @State private var searchText = ""
    @State private var showingSignInAlert = false

    // Cached computed properties for performance
    @State private var cachedFeaturedEvents: [Event] = []
    @State private var cachedThisWeekEvents: [Event] = []
    @State private var cachedPopularEvents: [Event] = []
    @State private var cachedNearbyEvents: [(event: Event, distance: CLLocationDistance)] = []
    @State private var cachedAllEvents: [Event] = []

    // Distance calculation cache
    @State private var distanceCache: [String: CLLocationDistance] = [:]
    @State private var lastUserLocation: CLLocation?

    // ✅ Maximum distance for "nearby" events (in meters)
    private let maxNearbyDistance: CLLocationDistance = 50_000 // ~31 miles

    // MARK: - Dynamic Genres from Firestore
    private var displayGenres: [String] {
        tagViewModel.displayTags
    }

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
    
    // MARK: - Nearby Events (Filtered by Distance)
    var nearbyEvents: [(event: Event, distance: CLLocationDistance)] {
        guard let userLocation = userLocationManager.currentCLLocation else {
            return []
        }

        let now = Date()

        // Get all upcoming events with coordinates
        let eventsWithCoordinates = eventViewModel.events
            .filter { event in
                guard let startTime = event.startTime,
                      let _ = event.coordinates else {
                    return false
                }
                return !event.isFeatured && startTime > now
            }

        // Calculate distance and filter by max distance
        let eventsWithDistance = eventsWithCoordinates.compactMap { event -> (Event, CLLocationDistance)? in
            guard let coordinates = event.coordinates else { return nil }
            let eventLocation = CLLocation(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            let distance = userLocation.distance(from: eventLocation)

            guard distance <= maxNearbyDistance else {
                return nil
            }

            return (event, distance)
        }

        // Sort by distance (closest first)
        return eventsWithDistance
            .sorted { $0.1 < $1.1 }
            .map { (event: $0.0, distance: $0.1) }
    }

    var nearbyEventsPreview: [(event: Event, distance: CLLocationDistance)] {
        Array(nearbyEvents.prefix(5))
    }

    // Helper function to format distance
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance * 0.000621371
        if miles < 0.1 {
            let feet = distance * 3.28084
            return String(format: "%.0fft", feet)
        } else {
            return String(format: "%.0fmi", round(miles))
        }
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
        ScrollView {
            VStack(spacing: 0) {
                // Header with Location Button
                HStack {
                    Text("Explore")
                        .appPageHeader()
                        .foregroundColor(.white)
                        .padding(.bottom, 2)


                    Spacer()

                    // Location Button - Top Right
                    Button(action: {
                        coordinator.activeModal = .SetLocation
                    }) {
                        ZStack {
                            Circle()
                                .stroke(
                                    userLocationManager.savedLocation != nil ? Color.white : Color.gray.opacity(0.5),
                                    lineWidth: 1
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: "map")
                                .appCard()
                                .foregroundColor(userLocationManager.savedLocation != nil ? .white : .gray.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 44)
                .padding(.bottom, 30)

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
        .task {
            // Initial cache computation
            updateAllCaches()
        }
        .onChange(of: eventViewModel.events) { _, _ in
            // Update caches when events change
            updateAllCaches()
        }
        .onChange(of: userLocationManager.currentCLLocation) { oldLocation, newLocation in
            // Only recalculate distances if location changed significantly (> 1km)
            if let old = oldLocation, let new = newLocation {
                let distance = old.distance(from: new)
                if distance > 1000 { // More than 1km
                    updateNearbyCacheInBackground()
                }
            } else if newLocation != nil {
                updateNearbyCacheInBackground()
            }
        }
        .onChange(of: coordinator.pendingDeepLink) { _, eventId in
            if let eventId = eventId {
                coordinator.navigate(to: .eventById(eventId))
            }
        }
        .overlay {
            if showingSignInAlert {
                CustomAlertView(
                    title: "Sign In Required",
                    description: "You need to be signed in to bookmark events.",
                    cancelAction: {
                            showingSignInAlert = false
                },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        showingSignInAlert = false
                        coordinator.showSignIn()
                    },
                    primaryActionTitle: "Sign In",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            CustomLoadingIndicator(size: 50)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    // MARK: - Cache Update Methods
    private func updateAllCaches() {
        cachedFeaturedEvents = featuredEvents
        cachedThisWeekEvents = thisWeekEvents
        cachedPopularEvents = popularEvents
        cachedAllEvents = allEvents
        updateNearbyCacheInBackground()
    }

    private func updateNearbyCacheInBackground() {
        Task {
            cachedNearbyEvents = nearbyEvents
        }
    }

    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            // 1st Featured Hero Card (Use Cached)
            if let featured = cachedFeaturedEvents.first {
                NavigationLink(value: NavigationDestination.eventDetail(featured)) {
                    FeaturedHeroCard(event: featured, bookmarkManager: bookmarkManager, showingSignInAlert: $showingSignInAlert)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Popular (Use Cached)
            if !cachedPopularEvents.isEmpty {
                EventSection(
                    title: "Popular",
                    events: Array(cachedPopularEvents.prefix(5)),
                    allEvents: cachedPopularEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: false,
                    showingSignInAlert: $showingSignInAlert
                )
            }

            // This Week (Use Cached)
            if !cachedThisWeekEvents.isEmpty {
                EventSection(
                    title: "This Week",
                    events: Array(cachedThisWeekEvents.prefix(5)),
                    allEvents: cachedThisWeekEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: false,
                    showingSignInAlert: $showingSignInAlert
                )
            }

            // 2nd Featured Card (Use Cached)
            if cachedFeaturedEvents.count > 1 {
                NavigationLink(value: NavigationDestination.eventDetail(cachedFeaturedEvents[1])) {
                    FeaturedHeroCard(event: cachedFeaturedEvents[1], bookmarkManager: bookmarkManager, showingSignInAlert: $showingSignInAlert)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Nearby (Use Cached)
            if userLocationManager.savedLocation != nil && !cachedNearbyEvents.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Nearby")
                            .appSectionHeader()
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    LazyVStack(spacing: 0) {
                        ForEach(Array(cachedNearbyEvents.prefix(5).enumerated()), id: \.element.event.id) { _, item in
                            NavigationLink(value: NavigationDestination.eventDetail(item.event)) {
                                EventRow(
                                    event: item.event,
                                    bookmarkManager: bookmarkManager,
                                    distanceText: formatDistance(item.distance),
                                    showingSignInAlert: $showingSignInAlert
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.bottom, 40)
            }

            // 👉 Genre sections now handle: third featured + genre cards + remaining featured interleaves
            genreSectionsWithFeaturedCardsView

            // All Events (Use Cached)
            if !cachedAllEvents.isEmpty {
                EventSection(
                    title: "All Events",
                    events: Array(cachedAllEvents.prefix(6)),
                    allEvents: cachedAllEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: cachedAllEvents.count > 6,
                    showingSignInAlert: $showingSignInAlert
                )
            }
        }
    }


    private var genreSectionsWithFeaturedCardsView: some View {
        let genresWithEvents = displayGenres.filter { !allEventsForGenre($0).isEmpty }

        return ForEach(Array(genresWithEvents.enumerated()), id: \.offset) { index, genre in
            let genreEvents = allEventsForGenre(genre)
            let genrePreview = eventsForGenrePreview(genre)

            Group {
                // --- Insert the "third" featured card right before the first genre section (Use Cached) ---
                if index == 0 {
                    if cachedFeaturedEvents.count > 2 {
                        // 3rd featured card (index 2)
                        NavigationLink(value: NavigationDestination.eventDetail(cachedFeaturedEvents[2])) {
                            FeaturedHeroCard(event: cachedFeaturedEvents[2], bookmarkManager: bookmarkManager, showingSignInAlert: $showingSignInAlert)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // ✅ Genre Cards live HERE, directly under that first in-loop featured card
                    GenreCardsSection(
                        genres: displayGenres,
                        allEventsForGenre: { g in allEventsForGenre(g) }
                    )
                }
                // --- For subsequent featured interleaves, continue your existing pattern (Use Cached) ---
                else if index % 2 == 0 {
                    // Start from the 4th featured card onward:
                    // index 2 -> featuredIndex 3, index 4 -> 4, etc.
                    let featuredIndex = 2 + (index / 2)
                    if featuredIndex < cachedFeaturedEvents.count {
                        NavigationLink(value: NavigationDestination.eventDetail(cachedFeaturedEvents[featuredIndex])) {
                            FeaturedHeroCard(event: cachedFeaturedEvents[featuredIndex], bookmarkManager: bookmarkManager, showingSignInAlert: $showingSignInAlert)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // --- The genre section itself ---
                EventSection(
                    title: genre,
                    events: genrePreview,
                    allEvents: genreEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: true,
                    showingSignInAlert: $showingSignInAlert
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
    let events: [Event]          // Preview events to display
    let allEvents: [Event]        // All events for navigation
    let bookmarkManager: BookmarkManager
    let showViewAllButton: Bool
    @Binding var showingSignInAlert: Bool

    init(
        title: String,
        events: [Event],
        allEvents: [Event]? = nil,
        bookmarkManager: BookmarkManager,
        showViewAllButton: Bool = true,
        showingSignInAlert: Binding<Bool> = .constant(false)
    ) {
        self.title = title
        self.events = events
        self.allEvents = allEvents ?? events
        self.bookmarkManager = bookmarkManager
        self.showViewAllButton = showViewAllButton
        self._showingSignInAlert = showingSignInAlert
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
                    NavigationLink(value: NavigationDestination.filteredEvents(
                        EventSectionDestination(title: title, events: allEvents)
                    )) {
                        Image(systemName: "chevron.right")
                            .font(.appIcon)
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)

            // Event List
            LazyVStack(spacing: 0) {
                ForEach(events) { event in
                    NavigationLink(value: NavigationDestination.eventDetail(event)) {
                        EventRow(
                            event: event,
                            bookmarkManager: bookmarkManager,
                            showingSignInAlert: $showingSignInAlert
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Genre Cards Section
struct GenreCardsSection: View {
    let genres: [String]
    let allEventsForGenre: (String) -> [Event]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(genres, id: \.self) { genre in
                        NavigationLink(value: NavigationDestination.filteredEvents(
                            EventSectionDestination(title: genre, events: allEventsForGenre(genre))
                        )) {
                            GenreCard(genreName: genre)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Genre Card
struct GenreCard: View {
    let genreName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Text in bottom left
            Text(genreName)
                .appCard()
                .foregroundColor(.white)
                .padding(16)
        }
        .frame(width: 140, height: 120)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
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
