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

    // Maximum distance for "nearby" events (in meters)
    private let maxNearbyDistance: CLLocationDistance = AppConstants.maxNearbyDistanceMeters

    // MARK: - Dynamic Genres from Firestore
    private var displayGenres: [String] {
        tagViewModel.displayTags
    }

    // MARK: - Featured Events
    var featuredEvents: [Event] {
        let now = Date()
        let featured = eventViewModel.events.filter { event in
            // Only show featured events that haven't started yet
            guard event.isFeatured else { return false }
            if let startTime = event.startTime {
                return startTime > now
            }
            return true // If no startTime, include it
        }
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
        guard let savedLocation = userLocationManager.savedLocation else {
            return []
        }
        let userLocation = userLocationManager.currentCLLocation ?? CLLocation(
            latitude: savedLocation.latitude,
            longitude: savedLocation.longitude
        )

        let now = Date()

        let eventsWithCoordinates = eventViewModel.events
            .filter { event in
                guard let startTime = event.startTime,
                      let _ = event.coordinates else {
                    return false
                }
                return !event.isFeatured && startTime > now
            }

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
        ErrorBoundary(
            errorTitle: "Failed to Load Events",
            errorMessage: eventViewModel.errorMessage ?? "Unable to load events. Please check your connection and try again.",
            onRetry: {
                eventViewModel.fetchEvents()
            }
        ) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Location Button
                    HStack {
                        Text("Explore")
                            .appPageHeader()
                            .foregroundColor(.white)
                            .padding(.bottom, 2)

                        Spacer()

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
            .refreshable {
                await eventViewModel.refreshEvents()
            }
            .navigationBarHidden(true)
            .background(Color.black)
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
            buildContentSections()
        }
    }

    // MARK: - Build Content Sections (final order with genre sections)
    @ViewBuilder
    private func buildContentSections() -> some View {
        // 1) Featured card (index 0)
        if let e0 = featuredEvents[safe: 0] {
            featuredCard(e0)
        }

        // 2) Popular
        if !popularEvents.isEmpty {
            EventSection(
                title: "Popular",
                events: popularEventsPreview,
                allEvents: popularEvents,
                bookmarkManager: bookmarkManager,
                showViewAllButton: false,
                showingSignInAlert: $showingSignInAlert
            )
        }

        // 3) This Week
        if !thisWeekEvents.isEmpty {
            EventSection(
                title: "This Week",
                events: thisWeekEventsPreview,
                allEvents: thisWeekEvents,
                bookmarkManager: bookmarkManager,
                showViewAllButton: false,
                showingSignInAlert: $showingSignInAlert
            )
        }

        // 4) Featured card (index 1)
        if let e1 = featuredEvents[safe: 1] {
            featuredCard(e1)
        }

        // 5) Nearby section + Featured card (linked together - only show if nearby events exist)
        if !nearbyEvents.isEmpty {
            nearbySection

            // Featured card (index 2) - only shows when nearby section shows
            if let e2 = featuredEvents[safe: 2] {
                featuredCard(e2)
            }
        } else if userLocationManager.currentCLLocation != nil {
            // Show "no events nearby" message when user has location but no nearby events
            noNearbyEventsMessage
        }

        // 6) Genre cards (horizontal scroll)
        if !displayGenres.isEmpty {
            GenreCardsScrollRow(genres: displayGenres, allEventsForGenre: { g in allEventsForGenre(g) })
        }

        // 7) Genre sections with featured cards interspersed every 2 sections
        buildGenreSectionsWithFeaturedCards()

        // 8) All Events
        if !allEvents.isEmpty {
            EventSection(
                title: "All Events",
                events: allEventsPreview,
                allEvents: allEvents,
                bookmarkManager: bookmarkManager,
                showViewAllButton: allEvents.count > 6,
                showingSignInAlert: $showingSignInAlert
            )
        }
    }

    // MARK: - Helper: Build Genre Sections with Featured Cards
    @ViewBuilder
    private func buildGenreSectionsWithFeaturedCards() -> some View {
        let genresWithEvents = displayGenres.filter { !allEventsForGenre($0).isEmpty }

        ForEach(Array(genresWithEvents.enumerated()), id: \.element) { index, genre in
            EventSection(
                title: genre,
                events: eventsForGenrePreview(genre),
                allEvents: allEventsForGenre(genre),
                bookmarkManager: bookmarkManager,
                showViewAllButton: true,
                showingSignInAlert: $showingSignInAlert
            )

            // Add featured card after every 2 genre sections
            // Featured cards start at index 3 (since 0, 1, 2 are used above)
            if (index + 1) % 2 == 0 {
                let featuredIndex = 3 + (index + 1) / 2 - 1
                if let featured = featuredEvents[safe: featuredIndex] {
                    featuredCard(featured)
                }
            }
        }
    }

    // MARK: - Helper: Featured Card
    @ViewBuilder
    private func featuredCard(_ event: Event) -> some View {
        NavigationLink(value: NavigationDestination.eventDetail(event)) {
            FeaturedHeroCard(
                event: event,
                bookmarkManager: bookmarkManager,
                showingSignInAlert: $showingSignInAlert
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper: Nearby Section
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nearby")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 0) {
                ForEach(Array(nearbyEventsPreview.enumerated()), id: \.element.event.id) { _, item in
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

    // MARK: - Helper: No Nearby Events Message
    private var noNearbyEventsMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)

            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)

                    Text("No events nearby")
                        .appBody()
                        .foregroundColor(.gray)

                    NavigationLink(value: NavigationDestination.filteredEvents(
                        EventSectionDestination(title: "All Events", events: allEvents)
                    )) {
                        Text("Click here to view all events")
                            .appSecondary()
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 32)
                Spacer()
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
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
    let allEvents: [Event]
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
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)

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

// MARK: - Genre Cards Horizontal Scroll
struct GenreCardsScrollRow: View {
    let genres: [String]
    let allEventsForGenre: (String) -> [Event]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(genres, id: \.self) { genre in
                    NavigationLink(value: NavigationDestination.filteredEvents(
                        EventSectionDestination(title: genre, events: allEventsForGenre(genre))
                    )) {
                        GenreCard(genreName: genre)
                            .frame(width: 140, height: 120)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
    }
}


// MARK: - Genre Card
struct GenreCard: View {
    let genreName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(genreName)
                .appCard()
                .foregroundColor(.white)
                .padding(16)
        }
        .frame(height: 120)
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

// MARK: - Utilities
extension Array {
    /// Splits the array into chunks of a fixed size (e.g. 2)
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        var result: [[Element]] = []
        var i = 0
        while i < count {
            let end = Swift.min(i + size, count)
            result.append(Array(self[i..<end]))
            i = end
        }
        return result
    }

    /// Safe subscript to avoid out-of-bounds
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
