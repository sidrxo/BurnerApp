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
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var userLocationManager: UserLocationManager
    @StateObject private var viewModel: SearchViewModel

    @State private var searchText = ""
    @State private var sortBy: SortOption = .date
    @State private var pendingNearbySortRequest = false
    @State private var showingSignInAlert = false
    @FocusState private var isSearchFocused: Bool

    init() {
        _viewModel = StateObject(wrappedValue: SearchViewModel())
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
            // Pass events from eventViewModel to searchViewModel
            viewModel.setSourceEvents(eventViewModel.events)
            // Only load if we have events, otherwise wait for onChange to trigger
            if !eventViewModel.events.isEmpty {
                await viewModel.loadInitialEvents(sortBy: sortBy.rawValue)
            }
        }
        .onChange(of: eventViewModel.events) { oldValue, newValue in
            // Update search results when events change from real-time listener
            viewModel.setSourceEvents(newValue)
            // Reload if this is the first time we're getting events
            if oldValue.isEmpty && !newValue.isEmpty {
                Task {
                    await viewModel.loadInitialEvents(sortBy: sortBy.rawValue)
                }
            }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EmptyStateEnabled"))) { _ in
            viewModel.clearAllResults()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EmptyStateDisabled"))) { _ in
            Task {
                await viewModel.loadInitialEvents(sortBy: sortBy.rawValue)
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

    private var sourceEvents: [Event] = [] // Events from AppState
    private var currentSearchText = ""
    private var searchCache: [String: (events: [Event], timestamp: Date)] = [:]

    private var searchCancellable: AnyCancellable?
    private let searchSubject = PassthroughSubject<(String, String), Never>()
    private let locationManager = LocationManager()

    // Cache TTL: 5 minutes
    private let cacheTTL: TimeInterval = 300

    init() {
        setupSearchDebouncing()
        setupLocationObserver()
    }

    // MARK: - Set Source Events from AppState
    func setSourceEvents(_ events: [Event]) {
        self.sourceEvents = events
        // Re-filter if there's an active search
        if !currentSearchText.isEmpty {
            Task {
                await performSearch(searchText: currentSearchText, sortBy: "startTime")
            }
        }
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
    
    // MARK: - Load Initial Events (From Cache)
    func loadInitialEvents(sortBy: String) async {
        guard !isLoading else { return }

        isLoading = true

        // Filter upcoming events from source
        let upcomingEvents = sourceEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > Date()
        }

        // Sort locally
        events = sortEvents(upcomingEvents, by: sortBy)

        isLoading = false
    }

    // MARK: - Sort Events Locally
    private func sortEvents(_ events: [Event], by sortBy: String) -> [Event] {
        switch sortBy {
        case "price":
            return events.sorted { $0.price < $1.price }
        case "date":
            return events.sorted {
                ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
            }
        default: // startTime
            return events.sorted {
                ($0.startTime ?? Date.distantPast) < ($1.startTime ?? Date.distantPast)
            }
        }
    }
    
    // MARK: - Perform Search (Local Filtering with Cache TTL)
    private func performSearch(searchText: String, sortBy: String) async {
        currentSearchText = searchText

        // Empty search - load regular events
        if searchText.isEmpty {
            await loadInitialEvents(sortBy: sortBy)
            return
        }

        // Check cache first with TTL validation
        let cacheKey = "\(searchText)_\(sortBy)"
        if let cached = searchCache[cacheKey] {
            let cacheAge = Date().timeIntervalSince(cached.timestamp)
            if cacheAge < cacheTTL {
                events = cached.events
                return
            } else {
                // Cache expired, remove it
                searchCache.removeValue(forKey: cacheKey)
            }
        }

        isLoading = true

        // Filter upcoming events from source
        let upcomingEvents = sourceEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > Date()
        }

        // Perform local text search
        let searchLower = searchText.lowercased()
        let searchResults = upcomingEvents.filter { event in
            event.name.lowercased().contains(searchLower) ||
            event.venue.lowercased().contains(searchLower) ||
            (event.description?.lowercased().contains(searchLower) ?? false) ||
            (event.tags?.contains(where: { $0.lowercased().contains(searchLower) }) ?? false)
        }

        // Sort results
        let sortedResults = sortEvents(searchResults, by: sortBy)

        events = sortedResults
        searchCache[cacheKey] = (events: sortedResults, timestamp: Date())

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

    // MARK: - Sort Events by Distance (Local Filtering - Optimized)
    private func sortEventsByDistance() async {
        guard let userLocation = userLocation else {
            errorMessage = "Location not available. Please enable location services."
            return
        }

        isLoading = true

        // Filter upcoming events from cached source
        let upcomingEvents = sourceEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > Date()
        }

        // Calculate distances and filter by max distance (50km)
        let maxDistance: CLLocationDistance = 50_000 // 50km
        let eventsWithDistance = upcomingEvents.compactMap { event -> (Event, CLLocationDistance)? in
            guard let coordinates = event.coordinates else {
                return nil
            }
            let eventLocation = CLLocation(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            let distance = userLocation.distance(from: eventLocation)

            // Only include events within 50km
            guard distance <= maxDistance else {
                return nil
            }

            return (event, distance)
        }

        // Sort by distance (closest first)
        let sortedEvents = eventsWithDistance
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }

        events = sortedEvents

        isLoading = false
    }

    // MARK: - Refresh Events
    func refreshEvents(sortBy: String) async {
        searchCache.removeAll()
        await loadInitialEvents(sortBy: sortBy)
    }

    // MARK: - Clear All Results (for Debug Empty State)
    func clearAllResults() {
        events = []
        searchCache.removeAll()
        isLoading = false
        isLoadingMore = false
        errorMessage = nil
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
                .font(.system(size: 60))
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
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
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
