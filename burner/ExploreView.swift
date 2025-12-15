import SwiftUI
import Kingfisher
import CoreLocation
import Supabase

struct ExploreView: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var tagViewModel: TagViewModel
    @EnvironmentObject var userLocationManager: UserLocationManager
    @Environment(\.heroNamespace) private var heroNamespace

    @State private var searchText = ""
    @State private var showingSignInAlert = false
    @StateObject private var localPreferences = LocalPreferences()
    
    // REMOVED: @State private var isRefreshing = false // Not needed with the fix
    
    @State private var featuredEvents: [Event] = []
    @State private var thisWeekEvents: [Event] = []
    @State private var nearbyEvents: [(event: Event, distance: CLLocationDistance)] = []
    @State private var popularEvents: [Event] = []
    @State private var genreEventCache: [String: [Event]] = [:]
    @State private var allEvents: [Event] = []
    @State private var isComputingInitialData = true

    private let maxNearbyDistance: CLLocationDistance = AppConstants.maxNearbyDistanceMeters

    private var displayGenres: [String] {
        let allGenres = tagViewModel.displayTags
        let selectedGenres = localPreferences.selectedGenres
        let selectedSet = Set(selectedGenres)
        let remainingGenres = allGenres.filter { !selectedSet.contains($0) }
        return selectedGenres + remainingGenres
    }

    var thisWeekEventsPreview: [Event] {
        Array(thisWeekEvents.prefix(5))
    }

    var nearbyEventsPreview: [(event: Event, distance: CLLocationDistance)] {
        Array(nearbyEvents.prefix(5))
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance * 0.000621371
        if miles < 0.1 {
            let feet = distance * 3.28084
            return String(format: "%.0fft", feet)
        } else {
            return String(format: "%.0fmi", round(miles))
        }
    }

    var popularEventsPreview: [Event] {
        Array(popularEvents.prefix(5))
    }

    func allEventsForGenre(_ genre: String) -> [Event] {
        genreEventCache[genre] ?? []
    }

    func eventsForGenrePreview(_ genre: String) -> [Event] {
        Array(allEventsForGenre(genre).prefix(5))
    }

    var allEventsPreview: [Event] {
        Array(allEvents.prefix(6))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
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
                            Image("map")
                                .appCard()
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .opacity(userLocationManager.savedLocation != nil ? 1.0 : 0.3)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .background(Color.black)
                .zIndex(1)

                ScrollView {
                    VStack(spacing: 0) {
                        if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                            loadingView
                        } else if isComputingInitialData {
                            loadingView
                        } else {
                            contentView
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 80)
                }
                .refreshable {
                    // FIX: Combine refresh and compute to ensure the animation waits for both.
                    await eventViewModel.refreshEvents()
                    await computeEventSections()
                    
                    // Small optional delay to ensure UI updates are rendered before dismissal
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
            }
            .navigationBarHidden(true)
            .onChange(of: coordinator.pendingDeepLink) { _, eventId in
                if let eventId = eventId {
                    coordinator.navigate(to: .eventById(eventId))
                }
            }
            .onChange(of: eventViewModel.errorMessage) { _, newError in
                // Removed redundant !isRefreshing check
                if newError != nil && !eventViewModel.events.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        eventViewModel.clearMessages()
                    }
                }
            }
            .onAppear {
                if isComputingInitialData && !eventViewModel.events.isEmpty {
                    Task {
                        try? await Task.sleep(nanoseconds: 50_000_000)
                        await computeEventSections()
                        isComputingInitialData = false
                    }
                }
            }
            .onChange(of: eventViewModel.events) { _, newEvents in
                guard !newEvents.isEmpty else { return }
                
                if isComputingInitialData {
                    Task {
                        try? await Task.sleep(nanoseconds: 50_000_000)
                        await computeEventSections()
                        isComputingInitialData = false
                    }
                } else {
                    // This is the code path for non-refresh related data changes (e.g., streaming)
                    // It is necessary if the event list can change outside of a full user-triggered refresh.
                    Task {
                        await computeEventSections()
                    }
                }
            }
            .onChange(of: userLocationManager.savedLocation) { _, _ in
                guard !isComputingInitialData else { return }
                Task {
                    await computeNearbyEvents()
                }
            }
            .onChange(of: displayGenres) { _, _ in
                guard !isComputingInitialData else { return }
                Task {
                    await computeGenreEvents()
                }
            }

            if eventViewModel.errorMessage != nil && eventViewModel.events.isEmpty {
                VStack(spacing: 24) {

                    Text("Failed to Load Events")
                        .appSectionHeader()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Please check your connection and try again.")
                        .appBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button(action: {
                        eventViewModel.clearMessages()
                        eventViewModel.fetchEvents()
                    }) {
                        Text("RELOAD")
                            .appMonospaced(size: 16)
                            .frame(width: 160)
                    }
                    .buttonStyle(SecondaryButton(backgroundColor: .white, foregroundColor: .black))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }

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
                    primaryActionColor: .white,
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }

    private func computeEventSections() async {
        let events = eventViewModel.events

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let computed = await computeFeaturedEvents(events: events)
                await MainActor.run { featuredEvents = computed }
            }

            group.addTask {
                let computed = await computeThisWeekEvents(events: events)
                await MainActor.run { thisWeekEvents = computed }
            }

            group.addTask {
                await computeNearbyEvents()
            }

            group.addTask {
                let computed = await computePopularEvents(events: events)
                await MainActor.run { popularEvents = computed }
            }

            group.addTask {
                await computeGenreEvents()
            }

            group.addTask {
                let computed = await computeAllEvents(events: events)
                await MainActor.run { allEvents = computed }
            }
        }
    }

    private func computeFeaturedEvents(events: [Event]) async -> [Event] {
        let now = Date()
        let featured = events.filter { event in
            guard event.isFeatured else { return false }
            if let startTime = event.startTime {
                return startTime > now
            }
            return true
        }

        return featured.sorted { event1, event2 in
            let priority1 = event1.featuredPriority ?? 999
            let priority2 = event2.featuredPriority ?? 999

            if priority1 != priority2 {
                return priority1 < priority2
            }

            let time1 = event1.startTime ?? Date.distantFuture
            let time2 = event2.startTime ?? Date.distantFuture
            return time1 < time2
        }
    }

    private func computeThisWeekEvents(events: [Event]) async -> [Event] {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfToday = calendar.startOfDay(for: now) as Date?,
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfToday) else {
            return []
        }

        return events
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

    private func computeNearbyEvents() async {
        guard let savedLocation = await MainActor.run(body: { userLocationManager.savedLocation }) else {
            await MainActor.run { nearbyEvents = [] }
            return
        }

        let currentCLLocation = await MainActor.run { userLocationManager.currentCLLocation }
        let userLocation = currentCLLocation ?? CLLocation(
            latitude: savedLocation.latitude,
            longitude: savedLocation.longitude
        )

        let events = await MainActor.run { eventViewModel.events }
        let now = Date()

        let eventsWithCoordinates = events
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

        let sorted = eventsWithDistance
            .sorted { $0.1 < $1.1 }
            .map { (event: $0.0, distance: $0.1) }

        await MainActor.run {
            nearbyEvents = sorted
        }
    }

    private func computePopularEvents(events: [Event]) async -> [Event] {
        let thisWeek = await computeThisWeekEvents(events: events)
        let thisWeekEventIds = Set(thisWeek.compactMap { $0.id })

        return events
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

    private func computeGenreEvents() async {
        let genres = await MainActor.run { displayGenres }
        let events = await MainActor.run { eventViewModel.events }

        var cache: [String: [Event]] = [:]

        for genre in genres {
            let filtered = events
                .filter { event in
                    guard let startTime = event.startTime else { return false }
                    return !event.isFeatured &&
                            startTime > Date() &&
                            (event.tags?.contains { $0.localizedCaseInsensitiveCompare(genre) == .orderedSame } ?? false)
                }
                .sorted { event1, event2 in
                    (event1.startTime ?? Date.distantPast) < (event2.startTime ?? Date.distantPast)
                }

            cache[genre] = filtered
        }

        await MainActor.run {
            genreEventCache = cache
        }
    }

    private func computeAllEvents(events: [Event]) async -> [Event] {
        return events
            .filter { event in
                guard let startTime = event.startTime else { return false }
                return startTime > Date()
            }
            .sorted { event1, event2 in
                (event1.startTime ?? Date.distantPast) < (event2.startTime ?? Date.distantPast)
            }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            // NEW: Optional message when offline
            if eventViewModel.errorMessage != nil {
                Text("Attempting to connect...")
                    .appBody()
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            buildContentSections()
        }
    }

    @ViewBuilder
    private func buildContentSections() -> some View {
        if let e0 = featuredEvents[safe: 0] {
            featuredCard(e0)
        }

        if !popularEvents.isEmpty {
            EventSection(
                title: "Popular",
                events: popularEventsPreview,
                allEvents: popularEvents,
                bookmarkManager: bookmarkManager,
                showViewAllButton: false,
                showingSignInAlert: $showingSignInAlert,
                namespace: heroNamespace
            )
        }

        if !thisWeekEvents.isEmpty {
            EventSection(
                title: "This Week",
                events: thisWeekEventsPreview,
                allEvents: thisWeekEvents,
                bookmarkManager: bookmarkManager,
                showViewAllButton: false,
                showingSignInAlert: $showingSignInAlert,
                namespace: heroNamespace
            )
        }

        if let e1 = featuredEvents[safe: 1] {
            featuredCard(e1)
        }

        if !nearbyEvents.isEmpty {
            nearbySection

            if let e2 = featuredEvents[safe: 2] {
                featuredCard(e2)
            }
        } else if userLocationManager.currentCLLocation != nil {
            noNearbyEventsMessage
        }

        if !displayGenres.isEmpty {
            GenreCardsScrollRow(genres: displayGenres, allEventsForGenre: { g in allEventsForGenre(g) })
        }

        buildGenreSectionsWithFeaturedCards(isLast: true)

        if !allEvents.isEmpty {
            HStack {
                Spacer()

                NavigationLink(
                    value: NavigationDestination.filteredEvents(
                        EventSectionDestination(title: "All Events", events: allEvents)
                    )
                ) {
                    HStack(spacing: 2) {
                        Text("All Events")
                            .appSecondary()
                            .foregroundColor(.gray)

                        Image(systemName: "chevron.right")
                            .font(.appSecondary)
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }

    @ViewBuilder
    private func buildGenreSectionsWithFeaturedCards(isLast: Bool = false) -> some View {
        let genresWithEvents = displayGenres.filter { !allEventsForGenre($0).isEmpty }

        ForEach(Array(genresWithEvents.enumerated()), id: \.element) { index, genre in
            EventSection(
                title: genre,
                events: eventsForGenrePreview(genre),
                allEvents: allEventsForGenre(genre),
                bookmarkManager: bookmarkManager,
                showViewAllButton: true,
                isLast: index == genresWithEvents.count - 1,
                showingSignInAlert: $showingSignInAlert,
                namespace: heroNamespace
            )

            if (index + 1) % 2 == 0 {
                let featuredIndex = 3 + (index + 1) / 2 - 1
                if let featured = featuredEvents[safe: featuredIndex] {
                    featuredCard(featured)
                }
            }
        }
    }

    @ViewBuilder
    private func featuredCard(_ event: Event) -> some View {
        NavigationLink(value: NavigationDestination.eventDetail(event.id ?? "")) {
            FeaturedHeroCard(
                event: event,
                bookmarkManager: bookmarkManager,
                showingSignInAlert: $showingSignInAlert,
                namespace: heroNamespace
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 40)
        }
        .buttonStyle(.noHighlight)
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nearby")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 10)

            LazyVStack(spacing: 0) {
                ForEach(Array(nearbyEventsPreview.enumerated()), id: \.element.event.id) { _, item in
                    NavigationLink(value: NavigationDestination.eventDetail(item.event.id ?? "")) {
                        EventRow(
                            event: item.event,
                            bookmarkManager: bookmarkManager,
                            distanceText: formatDistance(item.distance),
                            showingSignInAlert: $showingSignInAlert,
                            namespace: heroNamespace
                        )
                    }
                    .buttonStyle(.noHighlight)
                }
            }
        }
        .padding(.bottom, 40)
    }

    private var noNearbyEventsMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 10)

            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .appHero()
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
            .padding(.horizontal, 10)
        }
        .padding(.bottom, 40)
    }
}

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

struct EventSection: View {
    let title: String
    let events: [Event]
    let allEvents: [Event]
    let bookmarkManager: BookmarkManager
    let showViewAllButton: Bool
    let isLast: Bool
    @Binding var showingSignInAlert: Bool
    var namespace: Namespace.ID?

    init(
        title: String,
        events: [Event],
        allEvents: [Event]? = nil,
        bookmarkManager: BookmarkManager,
        showViewAllButton: Bool = true,
        isLast: Bool = false,
        showingSignInAlert: Binding<Bool> = .constant(false),
        namespace: Namespace.ID? = nil
    ) {
        self.title = title
        self.events = events
        self.allEvents = allEvents ?? events
        self.bookmarkManager = bookmarkManager
        self.showViewAllButton = showViewAllButton
        self._showingSignInAlert = showingSignInAlert
        self.namespace = namespace
        self.isLast = isLast
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
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)

            LazyVStack(spacing: 0) {
                ForEach(events) { event in
                    NavigationLink(value: NavigationDestination.eventDetail(event.id ?? "")) {
                        EventRow(
                            event: event,
                            bookmarkManager: bookmarkManager,
                            showingSignInAlert: $showingSignInAlert,
                            namespace: namespace
                        )
                    }
                    .buttonStyle(.noHighlight)
                }
            }
        }
        .padding(.bottom, isLast ? 20 : 40)
    }
}

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
            .padding(.horizontal, 10)
        }
        .padding(.bottom, 40)
    }
}

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

extension Event: Hashable {
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Array {
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

    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
