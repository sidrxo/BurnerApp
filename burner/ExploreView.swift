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
    @EnvironmentObject var locationManager: LocationManager

    @State private var searchText = ""
    @State private var selectedEvent: Event? = nil
    @State private var showingLocationPrompt = false

    // Maximum radius for nearby events (80km = ~50 miles)
    private let maxNearbyRadius: CLLocationDistance = 80_000 // 80km in meters

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
    
    // MARK: - Nearby Events (with better debugging)
    var nearbyEvents: [Event] {
        // Check if we have a current location
        guard let userLocation = locationManager.currentLocation else {
            print("🗺️ ExploreView: No current location available")
            return []
        }
        
        print("🗺️ ExploreView: User location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        print("🗺️ ExploreView: Total events to filter: \(eventViewModel.events.count)")
        
        // Count and list events with coordinates
        let eventsWithCoordinates = eventViewModel.events.filter { $0.coordinates != nil }
        print("🗺️ ExploreView: Events with coordinates: \(eventsWithCoordinates.count)")
        
        // Log which events have coordinates and their details
        for event in eventsWithCoordinates {
            let isFeatured = event.isFeatured
            let startTime = event.startTime
            let isPast = startTime.map { $0 <= Date() } ?? true
            print("🗺️ ExploreView: ✓ '\(event.name)' - Featured: \(isFeatured), StartTime: \(startTime?.description ?? "nil"), IsPast: \(isPast)")
        }
        
        let nearby = eventViewModel.events
            .filter { event in
                guard let startTime = event.startTime else {
                    return false
                }
                
                // Check if event is in the future
                if startTime <= Date() {
                    return false
                }
                
                // Allow all upcoming events (including featured)
                return true
            }
            .compactMap { event -> (event: Event, distance: CLLocationDistance)? in
                guard let coordinates = event.coordinates else {
                    return nil
                }
                let eventLocation = CLLocation(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
                let distance = userLocation.distance(from: eventLocation)
                
                // Filter by max radius
                guard distance <= maxNearbyRadius else {
                    print("🗺️ ExploreView: Event '\(event.name)' is too far: \(distance/1000)km (max: \(maxNearbyRadius/1000)km)")
                    return nil
                }
                
                print("🗺️ ExploreView: ✓ Event '\(event.name)' is \(distance/1000) km away - INCLUDED")
                return (event, distance)
            }
            .sorted { $0.distance < $1.distance }
            .map { $0.event }
        
        print("🗺️ ExploreView: Found \(nearby.count) nearby events within \(maxNearbyRadius/1000)km radius")
        return nearby
    }
    
    var nearbyEventsPreview: [Event] {
        Array(nearbyEvents.prefix(5))
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
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Map Button
                    ZStack {
                        HeaderSection(title: "Explore")
                        
                        // Map button overlaid on top right
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    showingLocationPrompt = true
                                }
                            }) {
                                Image(systemName: "map")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.trailing, 20)
                        }
                    }

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
            .onChange(of: coordinator.pendingDeepLink) { _, eventId in
                if let eventId = eventId {
                    print("🎯 ExploreView: Navigating to event \(eventId)")
                    coordinator.navigate(to: .eventById(eventId))
                }
            }
            .onAppear {
                // Debug print on appear
                print("🗺️ ExploreView appeared")
                print("🗺️ Total events: \(eventViewModel.events.count)")
                print("🗺️ Has location preference: \(locationManager.hasLocationPreference)")
                print("🗺️ Has location: \(locationManager.currentLocation != nil)")
                if let loc = locationManager.currentLocation {
                    print("🗺️ Location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
                }
            }
            
            // Location Prompt Modal
            if showingLocationPrompt {
                LocationPromptModal {
                    showingLocationPrompt = false
                }
                .environmentObject(locationManager)
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: showingLocationPrompt)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            CustomLoadingIndicator(size: 50)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            // Featured Hero Card
            if let featured = featuredEvents.first {
                NavigationLink(value: NavigationDestination.eventDetail(featured)) {
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
                    allEvents: popularEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: false
                )
            }
            
            // Nearby Section - Only show if user has set location preference at least once
            if locationManager.hasLocationPreference {
                EventSection(
                    title: "Nearby",
                    events: nearbyEventsPreview,
                    allEvents: nearbyEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: nearbyEvents.count > 5,
                    showDistance: true,
                    locationManager: locationManager
                )
            }
            
            // This Week Section
            if !thisWeekEvents.isEmpty {
                EventSection(
                    title: "This Week",
                    events: thisWeekEventsPreview,
                    allEvents: thisWeekEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: false
                )
            }

            // Genre Cards - Horizontal Scrolling
            GenreCardsSection(
                genres: displayGenres,
                allEventsForGenre: { genre in allEventsForGenre(genre) }
            )

            // Genre Sections
            genreSectionsWithFeaturedCards
            
            // All Events Section
            if !allEvents.isEmpty {
                EventSection(
                    title: "All Events",
                    events: allEventsPreview,
                    allEvents: allEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: allEvents.count > 6
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
                        NavigationLink(value: NavigationDestination.eventDetail(featuredEvents[featuredIndex])) {
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
                    allEvents: genreEvents,
                    bookmarkManager: bookmarkManager,
                    showViewAllButton: true
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

// MARK: - Reusable Event Section Component (UPDATED - removed subtitle)
struct EventSection: View {
    let title: String
    let events: [Event]
    let allEvents: [Event]
    let bookmarkManager: BookmarkManager
    let showViewAllButton: Bool
    let showDistance: Bool
    let locationManager: LocationManager?
    
    init(
        title: String,
        events: [Event],
        allEvents: [Event]? = nil,
        bookmarkManager: BookmarkManager,
        showViewAllButton: Bool = true,
        showDistance: Bool = false,
        locationManager: LocationManager? = nil
    ) {
        self.title = title
        self.events = events
        self.allEvents = allEvents ?? events
        self.bookmarkManager = bookmarkManager
        self.showViewAllButton = showViewAllButton
        self.showDistance = showDistance
        self.locationManager = locationManager
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(title)
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Spacer()
                
                // View All Button
                if showViewAllButton && !allEvents.isEmpty {
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
            
            // Event List or Empty State
            if events.isEmpty && title == "Nearby" {
                // Show empty state for nearby section
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    
                    Text("No nearby events")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("No events found near your location")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if !events.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(events) { event in
                        NavigationLink(value: NavigationDestination.eventDetail(event)) {
                            EventRow(
                                event: event,
                                bookmarkManager: bookmarkManager,
                                distanceText: showDistance && locationManager != nil ? getDistanceText(for: event) : nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }
    
    private func getDistanceText(for event: Event) -> String? {
        guard let locationManager = locationManager,
              let coordinates = event.coordinates else {
            return nil
        }
        return locationManager.formattedDistance(to: CLLocationCoordinate2D(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        ))
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
