import SwiftUI
import Kingfisher
import Combine
import FirebaseFirestore
import CoreLocation

// MARK: - Optimized SearchView
struct SearchView: View {
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userLocationManager: UserLocationManager
    @StateObject private var viewModel: SearchViewModel

    @State private var searchText = ""
    @State private var sortBy: SortOption = .date
    @State private var pendingNearbySortRequest = false
    @State private var showingSignInAlert = false
    @FocusState private var isSearchFocused: Bool

    init() {
        let repository = OptimizedEventRepository()
        _viewModel = StateObject(wrappedValue: SearchViewModel(eventRepository: repository))
    }

    enum SortOption: String {
        case date = "date"
        case price = "price"
        case nearby = "nearby"
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "Search")
            searchSection
            filtersSection
            contentSection
        }
        .navigationBarHidden(true)
        .background(Color.black)
        .task {
            await viewModel.loadInitialEvents(sortBy: sortBy.rawValue)
        }
        .refreshable {
            await viewModel.refreshEvents(sortBy: sortBy.rawValue)
        }
        .onChange(of: searchText) { oldValue, newValue in
            viewModel.updateSearchText(newValue, sortBy: sortBy.rawValue)
        }
        .onChange(of: sortBy) { oldValue, newValue in
            if newValue == .nearby {
                // Use shared location manager
                if userLocationManager.savedLocation != nil {
                    // Already have location, sort immediately
                    Task {
                        await viewModel.changeSort(to: newValue.rawValue, searchText: searchText)
                    }
                } else {
                    // Need to request location
                    viewModel.requestLocationPermission()
                    pendingNearbySortRequest = true
                }
            } else {
                Task {
                    await viewModel.changeSort(to: newValue.rawValue, searchText: searchText)
                }
            }
        }
        .onChange(of: (viewModel.userLocation.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" })) { _, newKey in
            if pendingNearbySortRequest, newKey != nil {
                pendingNearbySortRequest = false
                Task { await viewModel.changeSort(to: sortBy.rawValue, searchText: searchText) }
            }
        }
        .onChange(of: userLocationManager.savedLocation?.name) { _, newName in
            if sortBy == .nearby, newName != nil {
                Task { await viewModel.changeSort(to: sortBy.rawValue, searchText: searchText) }
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
                        appState.isSignInSheetPresented = true
                    },
                    primaryActionTitle: "Sign In",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
    
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.appIcon)
                    .foregroundColor(.gray)

                TextField("Search events", text: $searchText)
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
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = true
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var filtersSection: some View {
        HStack(spacing: 12) {
            FilterButton(
                title: "DATE",
                isSelected: sortBy == .date
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    sortBy = .date
                }
            }

            FilterButton(
                title: "PRICE",
                isSelected: sortBy == .price
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    sortBy = .price
                }
            }

            FilterButton(
                title: nearbyButtonTitle,
                isSelected: sortBy == .nearby
            ) {
                // If already on nearby, show location modal to reset
                if sortBy == .nearby {
                    coordinator.activeModal = .SetLocation
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sortBy = .nearby
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private var nearbyButtonTitle: String {
        // If user has set a location and nearby is selected, show the city name
        if let savedLocation = userLocationManager.savedLocation {
            // Extract city name (remove any state/country info)
            let cityName = savedLocation.name.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? savedLocation.name
            return cityName.uppercased()
        }
        return "NEARBY"
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading && viewModel.events.isEmpty {
                        loadingView
                    } else if viewModel.events.isEmpty {
                        EmptyEventsView(searchText: searchText)
                    } else {
                        ForEach(viewModel.events) { event in
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
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            CustomLoadingIndicator(size: 50)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}


@MainActor
class SearchViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocation?

    private var hasMoreEvents = true
    private var lastDocument: Date?
    private var currentSearchText = ""
    private var searchCache: [String: [Event]] = [:]

    private let eventRepository: OptimizedEventRepository
    private var searchCancellable: AnyCancellable?
    private let searchSubject = PassthroughSubject<(String, String), Never>()
    private let locationManager = LocationManager()

    // ADD THIS: Constant for initial load limit
    private let initialLoadLimit = 6
    private let paginationLimit = 10

    init(eventRepository: OptimizedEventRepository) {
        self.eventRepository = eventRepository
        setupSearchDebouncing()
        setupLocationObserver()
    }

    private func setupLocationObserver() {
        locationManager.onLocationUpdate = { [weak self] location in
            Task { @MainActor in
                self?.userLocation = location
            }
        }
    }

    func requestLocationPermission() {
        locationManager.requestLocation()
    }
    
    // MARK: - Setup Search Debouncing
    private func setupSearchDebouncing() {
        searchCancellable = searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] (searchText, sortBy) in
                Task {
                    await self?.performSearch(searchText: searchText, sortBy: sortBy)
                }
            }
    }
    
    // MARK: - Update Search Text (Debounced)
    func updateSearchText(_ text: String, sortBy: String) {
        searchSubject.send((text, sortBy))
    }
    
    // MARK: - Load Initial Events
    func loadInitialEvents(sortBy: String) async {
        guard !isLoading else { return }

        isLoading = true
        hasMoreEvents = true
        lastDocument = nil

        do {
            // CHANGED: Use initialLoadLimit (5) instead of 20
            let fetchedEvents = try await eventRepository.fetchUpcomingEvents(
                sortBy: sortBy,
                limit: initialLoadLimit
            )

            events = fetchedEvents
            lastDocument = fetchedEvents.last?.startTime
            // CHANGED: Check against initialLoadLimit
            hasMoreEvents = fetchedEvents.count >= initialLoadLimit

        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load More Events (Pagination)
    func loadMoreEvents(sortBy: String, searchText: String) async {
        guard !isLoadingMore && hasMoreEvents && searchText.isEmpty else { return }
        
        isLoadingMore = true
        
        do {
            // Use paginationLimit (20) for subsequent loads
            let fetchedEvents = try await eventRepository.fetchUpcomingEvents(
                sortBy: sortBy,
                limit: paginationLimit,
                startAfter: lastDocument
            )
            
            events.append(contentsOf: fetchedEvents)
            lastDocument = fetchedEvents.last?.startTime
            hasMoreEvents = fetchedEvents.count >= paginationLimit
            
        } catch {
            errorMessage = "Failed to load more events: \(error.localizedDescription)"
        }
        
        isLoadingMore = false
    }
    
    // MARK: - Perform Search
    private func performSearch(searchText: String, sortBy: String) async {
        currentSearchText = searchText

        // Empty search - load regular events
        if searchText.isEmpty {
            await loadInitialEvents(sortBy: sortBy)
            return
        }

        // Check cache first
        let cacheKey = "\(searchText)_\(sortBy)"
        if let cached = searchCache[cacheKey] {
            events = cached
            return
        }

        isLoading = true

        do {
            let searchResults = try await eventRepository.searchEvents(
                searchText: searchText,
                sortBy: sortBy,
                limit: 50
            )

            events = searchResults
            searchCache[cacheKey] = searchResults
            hasMoreEvents = false // Disable pagination for search results

        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isLoading = false
    }
    
    // MARK: - Change Sort
    func changeSort(to sortBy: String, searchText: String) async {
        if sortBy == "nearby" {
            await sortEventsByDistance()
        } else if searchText.isEmpty {
            await loadInitialEvents(sortBy: sortBy)
        } else {
            await performSearch(searchText: searchText, sortBy: sortBy)
        }
    }

    // MARK: - Sort Events by Distance
    private func sortEventsByDistance() async {
        print("SearchViewModel: sortEventsByDistance called")
        guard let userLocation = userLocation else {
            print("SearchViewModel: No user location available")
            errorMessage = "Location not available. Please enable location services."
            return
        }

        print("SearchViewModel: User location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        isLoading = true

        do {
            // Fetch all upcoming events without limit for nearby sorting
            let allEvents = try await eventRepository.fetchUpcomingEvents(sortBy: "startTime", limit: 100)
            print("SearchViewModel: Fetched \(allEvents.count) events")

            // Calculate distance for each event and filter events with coordinates
            let eventsWithDistance = allEvents.compactMap { event -> (Event, CLLocationDistance)? in
                guard let coordinates = event.coordinates else {
                    print("SearchViewModel: Event '\(event.name)' has no coordinates")
                    return nil
                }
                let eventLocation = CLLocation(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
                let distance = userLocation.distance(from: eventLocation)
                print("SearchViewModel: Event '\(event.name)' distance: \(distance / 1000) km")
                return (event, distance)
            }

            print("SearchViewModel: \(eventsWithDistance.count) events have coordinates")

            // Sort by distance
            let sortedEvents = eventsWithDistance
                .sorted { $0.1 < $1.1 }
                .map { $0.0 }

            events = sortedEvents
            hasMoreEvents = false // Disable pagination for nearby view
            print("SearchViewModel: Sorted events by distance, showing \(sortedEvents.count) events")

        } catch {
            print("SearchViewModel: Error sorting by distance: \(error.localizedDescription)")
            errorMessage = "Failed to sort events by distance: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Refresh Events
    func refreshEvents(sortBy: String) async {
        searchCache.removeAll()
        await loadInitialEvents(sortBy: sortBy)
    }
}

// MARK: - Optimized Event Repository
@MainActor
class OptimizedEventRepository {
    private let db = Firestore.firestore()
    
    // MARK: - Fetch Upcoming Events (Paginated)
    func fetchUpcomingEvents(
        sortBy: String = "startTime",
        limit: Int = 20,
        startAfter: Date? = nil
    ) async throws -> [Event] {
        // Build base query with ordering by createdAt for date sort
        var query = db.collection("events")
            .order(by: sortBy == "date" ? "createdAt" : "startTime")
            .limit(to: limit * 2)

        if let startAfter = startAfter {
            query = query.start(after: [startAfter])
        }

        let snapshot = try await query.getDocuments()

        let allEvents = snapshot.documents.compactMap { doc -> Event? in
            var event = try? doc.data(as: Event.self)
            event?.id = doc.documentID
            return event
        }

        // Filter client-side for events with startTime > now
        let filteredEvents = allEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > Date()
        }

        // Sort client-side if needed
        let sortedEvents: [Event]
        if sortBy == "price" {
            sortedEvents = filteredEvents.sorted { $0.price < $1.price }
        } else if sortBy == "date" {
            // Sort by createdAt ascending (oldest first)
            sortedEvents = filteredEvents.sorted {
                ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
            }
        } else {
            // Already sorted by startTime from Firestore query
            sortedEvents = filteredEvents
        }

        return Array(sortedEvents.prefix(limit))
    }

    func searchEvents(
        searchText: String,
        sortBy: String = "startTime",
        limit: Int = 50
    ) async throws -> [Event] {
        // Fetch all events without date filtering
        let snapshot = try await db.collection("events")
            .limit(to: limit * 2)
            .getDocuments()

        let allEvents = snapshot.documents.compactMap { doc -> Event? in
            var event = try? doc.data(as: Event.self)
            event?.id = doc.documentID
            return event
        }

        // Filter for upcoming events with startTime
        let upcomingEvents = allEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > Date()
        }

        // Filter by search text
        let searchLower = searchText.lowercased()
        let searchResults = upcomingEvents.filter { event in
            event.name.lowercased().contains(searchLower) ||
            event.venue.lowercased().contains(searchLower) ||
            (event.description?.lowercased().contains(searchLower) ?? false) ||
            (event.tags?.contains(where: { $0.lowercased().contains(searchLower) }) ?? false)
        }

        // Sort client-side
        let sortedResults = searchResults.sorted { event1, event2 in
            if sortBy == "price" {
                return event1.price < event2.price
            } else if sortBy == "date" {
                // Sort by createdAt ascending (oldest first)
                return (event1.createdAt ?? Date.distantPast) < (event2.createdAt ?? Date.distantPast)
            } else {
                return (event1.startTime ?? Date.distantFuture) < (event2.startTime ?? Date.distantFuture)
            }
        }

        return Array(sortedResults.prefix(limit))
    }
}
// MARK: - Empty Events View
struct EmptyEventsView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)

            Image(systemName: searchText.isEmpty ? "calendar.badge.exclamationmark" : "magnifyingglass")
                .font(.appLargeIcon)
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Upcoming Events" : "No Search Results")
                    .font(.appBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(searchText.isEmpty ?
                     "There are no upcoming events available at the moment." :
                     "Try searching with different keywords.")
                    .font(.appBody)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        print("LocationManager: Requesting location, current status: \(manager.authorizationStatus.rawValue)")

        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            print("LocationManager: Requesting authorization")
            manager.requestWhenInUseAuthorization()
            // Don't call requestLocation here - wait for authorization callback
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationManager: Already authorized, requesting location")
            manager.requestLocation()
        case .denied, .restricted:
            print("LocationManager: Location access denied or restricted")
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("LocationManager: Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        onLocationUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("LocationManager: Authorization changed to: \(manager.authorizationStatus.rawValue)")
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            print("LocationManager: Now authorized, requesting location")
            manager.requestLocation()
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(AppState().bookmarkManager)
            .preferredColorScheme(.dark)
    }
}
