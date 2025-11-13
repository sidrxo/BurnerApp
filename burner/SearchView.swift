import SwiftUI
import Kingfisher
import Combine
import FirebaseFirestore
import CoreLocation

// MARK: - Event Handlers ViewModifier
struct SearchEventHandlers: ViewModifier {
    @ObservedObject var eventViewModel: EventViewModel
    @Binding var searchText: String
    @Binding var sortBy: SearchView.SortOption?
    @ObservedObject var viewModel: SearchViewModel
    @ObservedObject var userLocationManager: UserLocationManager
    let locationAuthStatus: CLAuthorizationStatus
    @Binding var showingLocationPermissionAlert: Bool
    @Binding var pendingNearbySortRequest: Bool
    let handleLocationUpdate: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: eventViewModel.events) { oldValue, newValue in
                viewModel.setSourceEvents(newValue)
            }
            .onChange(of: searchText) { oldValue, newValue in
                if let currentSort = sortBy {
                    viewModel.updateSearchText(newValue, sortBy: currentSort.rawValue)
                }
            }
            .onChange(of: sortBy) { oldValue, newValue in
                handleSortChange(oldValue: oldValue, newValue: newValue)
            }
            .onChange(of: viewModel.userLocation?.coordinate.latitude) { _, _ in
                handleLocationUpdate()
            }
            .onChange(of: viewModel.userLocation?.coordinate.longitude) { _, _ in
                handleLocationUpdate()
            }
            .onChange(of: userLocationManager.savedLocation) { oldValue, newValue in
                handleSavedLocationChange(oldValue: oldValue, newValue: newValue)
            }
            .onAppear {
                handleOnAppear()
            }
    }

    private func handleSortChange(oldValue: SearchView.SortOption?, newValue: SearchView.SortOption?) {
        guard let newValue = newValue else { return }

        if newValue == .nearby {
            if userLocationManager.savedLocation != nil {
                Task {
                    await viewModel.changeSort(to: newValue.rawValue, searchText: searchText)
                }
            } else {
                let authStatus = locationAuthStatus
                if authStatus == .notDetermined {
                    showingLocationPermissionAlert = true
                    pendingNearbySortRequest = true
                } else if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
                    viewModel.requestLocationPermission()
                    pendingNearbySortRequest = true
                } else {
                    sortBy = oldValue
                }
            }
        } else {
            Task {
                await viewModel.changeSort(to: newValue.rawValue, searchText: searchText)
            }
        }
    }

    private func handleSavedLocationChange(oldValue: UserLocation?, newValue: UserLocation?) {
        // Update viewModel's userLocation
        if let newLocation = newValue {
            viewModel.userLocation = CLLocation(
                latitude: newLocation.latitude,
                longitude: newLocation.longitude
            )
        }

        // If nearby sort is active, refresh the results with the new location
        if sortBy == .nearby, newValue != nil {
            Task {
                await viewModel.changeSort(to: "nearby", searchText: searchText)
            }
        }
    }

    private func handleOnAppear() {
        // Sync location from userLocationManager to viewModel
        if let savedLocation = userLocationManager.savedLocation {
            viewModel.userLocation = CLLocation(
                latitude: savedLocation.latitude,
                longitude: savedLocation.longitude
            )
        }

        // Refresh current sort
        if let currentSort = sortBy {
            Task {
                await viewModel.changeSort(to: currentSort.rawValue, searchText: searchText)
            }
        }
    }
}

// MARK: - Optimized SearchView
struct SearchView: View {
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var userLocationManager: UserLocationManager
    @StateObject private var viewModel: SearchViewModel

    @State private var searchText = ""
    @State private var sortBy: SortOption? = .date
    @State private var pendingNearbySortRequest = false
    @State private var showingSignInAlert = false
    @State private var showingLocationPermissionAlert = false
    @FocusState private var isSearchFocused: Bool

    init() {
        _viewModel = StateObject(wrappedValue: SearchViewModel())
    }

    // Helper to get authorizationStatus
    private var locationAuthStatus: CLAuthorizationStatus {
        return CLLocationManager().authorizationStatus
    }

    enum SortOption: String {
        case date = "date"
        case price = "price"
        case nearby = "nearby"
    }

    var body: some View {
        mainContent
            .navigationBarHidden(true)
            .background(Color.black)
            .task {
                setupInitialState()
            }
            .modifier(SearchEventHandlers(
                eventViewModel: eventViewModel,
                searchText: $searchText,
                sortBy: $sortBy,
                viewModel: viewModel,
                userLocationManager: userLocationManager,
                locationAuthStatus: locationAuthStatus,
                showingLocationPermissionAlert: $showingLocationPermissionAlert,
                pendingNearbySortRequest: $pendingNearbySortRequest,
                handleLocationUpdate: handleLocationUpdate
            ))
            .overlay {
                alertsOverlay
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "Search")
            searchSection
            filtersSection
            contentSection
        }
    }

    private var alertsOverlay: some View {
        Group {
            if showingSignInAlert {
                signInAlertView
            }

            if showingLocationPermissionAlert {
                locationPermissionAlertView
            }
        }
    }

    private var signInAlertView: some View {
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

    private var locationPermissionAlertView: some View {
        CustomAlertView(
            title: "Find Events Near You",
            description: "We'll show you events within 30 miles of your location. Your location is only used for finding nearby events and is never shared.",
            cancelAction: {
                showingLocationPermissionAlert = false
                pendingNearbySortRequest = false
                sortBy = nil
            },
            cancelActionTitle: "Not Now",
            primaryAction: {
                showingLocationPermissionAlert = false
                viewModel.requestLocationPermission()
            },
            primaryActionTitle: "Allow",
            customContent: EmptyView()
        )
        .transition(.opacity)
        .zIndex(999)
    }

    private func setupInitialState() {
        viewModel.setLocationManager(userLocationManager)
        viewModel.setSourceEvents(eventViewModel.events)
    }
    
    // Helper function to handle location updates
    private func handleLocationUpdate() {
        if pendingNearbySortRequest, viewModel.userLocation != nil {
            pendingNearbySortRequest = false
            Task {
                await viewModel.changeSort(to: sortBy?.rawValue ?? "date", searchText: searchText)
            }
        }
    }
    
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Show loading indicator when searching, otherwise show magnifying glass
                if viewModel.isLoading && !searchText.isEmpty {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.gray)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.appIcon)
                        .foregroundColor(.gray)
                }

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
                // Haptic feedback for filter change
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()

                withAnimation(.easeInOut(duration: AppConstants.standardAnimationDuration)) {
                    sortBy = .date
                }
            }

            FilterButton(
                title: "PRICE",
                isSelected: sortBy == .price
            ) {
                // Haptic feedback for filter change
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()

                withAnimation(.easeInOut(duration: AppConstants.standardAnimationDuration)) {
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
                    // Haptic feedback for filter change
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()

                    withAnimation(.easeInOut(duration: AppConstants.standardAnimationDuration)) {
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
            .refreshable {
                if let currentSort = sortBy {
                    await viewModel.refreshEvents(sortBy: currentSort.rawValue, searchText: searchText)
                }
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
    private var currentSortBy = ""
    private var searchCache: [String: (events: [Event], timestamp: Date)] = [:]

    private var searchCancellable: AnyCancellable?
    private let searchSubject = PassthroughSubject<(String, String), Never>()
    private weak var userLocationManager: UserLocationManager?

    // Cache TTL
    private let cacheTTL: TimeInterval = AppConstants.searchCacheTTL
    private let maxResultsPerFilter = 10

    init(userLocationManager: UserLocationManager? = nil) {
        self.userLocationManager = userLocationManager
        setupSearchDebouncing()
    }

    // MARK: - Set Source Events from AppState
    func setSourceEvents(_ events: [Event]) {
        self.sourceEvents = events
        // Re-filter if there's an active sort
        if !currentSortBy.isEmpty {
            Task {
                if !currentSearchText.isEmpty {
                    await performSearch(searchText: currentSearchText, sortBy: currentSortBy)
                } else {
                    await loadFilteredEvents(sortBy: currentSortBy)
                }
            }
        }
    }

    func setLocationManager(_ manager: UserLocationManager) {
        self.userLocationManager = manager
        // Update userLocation from saved location
        if let savedLocation = manager.currentCLLocation {
            self.userLocation = savedLocation
        }
    }

    func requestLocationPermission() {
        guard let userLocationManager = userLocationManager else { return }
        userLocationManager.requestCurrentLocation { [weak self] result in
            switch result {
            case .success(let location):
                Task { @MainActor in
                    self?.userLocation = CLLocation(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                }
            case .failure:
                break
            }
        }
    }
    
    // MARK: - Setup Search Debouncing
    private func setupSearchDebouncing() {
        searchCancellable = searchSubject
            .debounce(for: .milliseconds(AppConstants.searchDebounceMilliseconds), scheduler: DispatchQueue.main)
            .sink { [weak self] (searchText, sortBy) in
                Task {
                    await self?.performSearch(searchText: searchText, sortBy: sortBy)
                }
            }
    }
    
    // MARK: - Update Search Text (Debounced)
    func updateSearchText(_ text: String, sortBy: String) {
        currentSearchText = text
        currentSortBy = sortBy
        
        if text.isEmpty {
            // If search is cleared, reload filtered results
            Task {
                await loadFilteredEvents(sortBy: sortBy)
            }
        } else {
            searchSubject.send((text, sortBy))
        }
    }
    
    // MARK: - Load Filtered Events (Top 10 by filter type)
    func loadFilteredEvents(sortBy: String) async {
        guard !isLoading else { return }

        isLoading = true
        currentSortBy = sortBy

        // Filter upcoming events from source
        let upcomingEvents = sourceEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > Date()
        }

        // Sort and take top 10
        let sorted = sortEvents(upcomingEvents, by: sortBy)
        events = Array(sorted.prefix(maxResultsPerFilter))

        isLoading = false
    }

    // MARK: - Sort Events Locally
    private func sortEvents(_ events: [Event], by sortBy: String) -> [Event] {
        switch sortBy {
        case "price":
            return events.sorted { $0.price < $1.price }
        case "nearby":
            // This shouldn't be called directly for nearby - use sortEventsByDistance instead
            return events.sorted {
                ($0.startTime ?? Date.distantPast) < ($1.startTime ?? Date.distantPast)
            }
        default: // "date" or startTime
            return events.sorted {
                ($0.startTime ?? Date.distantPast) < ($1.startTime ?? Date.distantPast)
            }
        }
    }
    
    // MARK: - Perform Search (Local Filtering with Cache TTL)
    private func performSearch(searchText: String, sortBy: String) async {
        currentSearchText = searchText
        currentSortBy = sortBy

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

        // Sort results based on current filter
        let sortedResults: [Event]
        if sortBy == "nearby" {
            sortedResults = await sortSearchResultsByDistance(searchResults)
        } else {
            sortedResults = sortEvents(searchResults, by: sortBy)
        }

        events = sortedResults
        searchCache[cacheKey] = (events: sortedResults, timestamp: Date())

        isLoading = false
    }
    
    // MARK: - Change Sort
    func changeSort(to sortBy: String, searchText: String) async {
        currentSortBy = sortBy
        currentSearchText = searchText
        
        if sortBy == "nearby" {
            if searchText.isEmpty {
                await sortEventsByDistance()
            } else {
                await performSearch(searchText: searchText, sortBy: sortBy)
            }
        } else if searchText.isEmpty {
            await loadFilteredEvents(sortBy: sortBy)
        } else {
            await performSearch(searchText: searchText, sortBy: sortBy)
        }
    }

    // MARK: - Sort Events by Distance (Local Filtering - Optimized)
    private func sortEventsByDistance() async {
        guard let userLocation = userLocation else {
            errorMessage = "Location not available. Please enable location services."
            isLoading = false
            return
        }

        isLoading = true

        // Filter upcoming events from cached source
        let upcomingEvents = sourceEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > Date()
        }

        // Calculate distances and filter by max distance
        let maxDistance: CLLocationDistance = AppConstants.maxNearbyDistanceMeters
        let eventsWithDistance = upcomingEvents.compactMap { event -> (Event, CLLocationDistance)? in
            guard let coordinates = event.coordinates else {
                return nil
            }
            let eventLocation = CLLocation(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            let distance = userLocation.distance(from: eventLocation)

            // Only include events within max distance
            guard distance <= maxDistance else {
                return nil
            }

            return (event, distance)
        }

        // Sort by distance (closest first) and take top 10
        let sortedEvents = eventsWithDistance
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }

        events = Array(sortedEvents.prefix(maxResultsPerFilter))

        isLoading = false
    }

    // MARK: - Sort Search Results by Distance (for when searching with nearby filter)
    private func sortSearchResultsByDistance(_ searchResults: [Event]) async -> [Event] {
        guard let userLocation = userLocation else {
            return searchResults
        }

        let maxDistance: CLLocationDistance = AppConstants.maxNearbyDistanceMeters
        let eventsWithDistance = searchResults.compactMap { event -> (Event, CLLocationDistance)? in
            guard let coordinates = event.coordinates else {
                return nil
            }
            let eventLocation = CLLocation(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            let distance = userLocation.distance(from: eventLocation)

            guard distance <= maxDistance else {
                return nil
            }

            return (event, distance)
        }

        return eventsWithDistance
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    // MARK: - Refresh Events
    func refreshEvents(sortBy: String, searchText: String) async {
        searchCache.removeAll()
        currentSortBy = sortBy
        currentSearchText = searchText

        if searchText.isEmpty {
            if sortBy == "nearby" {
                await sortEventsByDistance()
            } else {
                await loadFilteredEvents(sortBy: sortBy)
            }
        } else {
            await performSearch(searchText: searchText, sortBy: sortBy)
        }
    }
}
