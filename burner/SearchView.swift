import SwiftUI
import Kingfisher
import Combine
import FirebaseFirestore
import CoreLocation

// MARK: - Optimized SearchView (Single Source of Truth)
struct SearchView: View {
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var eventViewModel: EventViewModel  // ✅ Single source of truth
    @EnvironmentObject var userLocationManager: UserLocationManager
    @Environment(\.heroNamespace) private var heroNamespace

    @State private var searchText = ""
    @State private var sortBy: SortOption? = .date
    @State private var showingSignInAlert = false
    @State private var showingLocationPermissionAlert = false
    @State private var pendingNearbySortRequest = false
    @FocusState private var isSearchFocused: Bool
    
    // Debouncing for search
    @State private var searchTask: Task<Void, Never>?
    @State private var debouncedSearchText = ""

    enum SortOption: String {
        case date = "date"
        case price = "price"
        case nearby = "nearby"
    }

    // MARK: - Computed Filtered Events (Single Source of Truth)
    private var filteredEvents: [Event] {
        let now = Date()
        
        // Start with upcoming events from EventViewModel (single source of truth)
        var events = eventViewModel.events.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime > now
        }
        
        // Apply search filter
        if !debouncedSearchText.isEmpty {
            let searchLower = debouncedSearchText.lowercased()
            events = events.filter { event in
                event.name.lowercased().contains(searchLower) ||
                event.venue.lowercased().contains(searchLower) ||
                (event.description?.lowercased().contains(searchLower) ?? false) ||
                (event.tags?.contains(where: { $0.lowercased().contains(searchLower) }) ?? false)
            }
        }
        
        // Apply sort
        switch sortBy {
        case .date, .none:
            events.sort { ($0.startTime ?? Date.distantPast) < ($1.startTime ?? Date.distantPast) }
            
        case .price:
            events.sort { $0.price < $1.price }
            
        case .nearby:
            if let userLocation = userLocationManager.currentCLLocation {
                let maxDistance: CLLocationDistance = AppConstants.maxNearbyDistanceMeters
                
                // Filter events with coordinates and within range
                let eventsWithDistance = events.compactMap { event -> (Event, CLLocationDistance)? in
                    guard let coordinates = event.coordinates else { return nil }
                    let eventLocation = CLLocation(
                        latitude: coordinates.latitude,
                        longitude: coordinates.longitude
                    )
                    let distance = userLocation.distance(from: eventLocation)
                    guard distance <= maxDistance else { return nil }
                    return (event, distance)
                }
                
                // Sort by distance and return events only
                events = eventsWithDistance
                    .sorted { $0.1 < $1.1 }
                    .map { $0.0 }
            }
        }
        
        // Limit to top 10 results
        return Array(events.prefix(10))
    }

    var body: some View {
        mainContent
            .navigationBarHidden(true)
            .background(Color.black)
            .onChange(of: searchText) { oldValue, newValue in
                handleSearchTextChange(newValue)
            }
            .onChange(of: sortBy) { oldValue, newValue in
                handleSortChange(oldValue: oldValue, newValue: newValue)
            }
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
                requestLocationPermission()
            },
            primaryActionTitle: "Allow",
            customContent: EmptyView()
        )
        .transition(.opacity)
        .zIndex(999)
    }
    
    // MARK: - Search Text Handler (with Debouncing)
    private func handleSearchTextChange(_ newValue: String) {
        // Cancel previous search task
        searchTask?.cancel()
        
        // Create new debounced search task
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            if !Task.isCancelled {
                await MainActor.run {
                    debouncedSearchText = newValue
                }
            }
        }
    }
    
    // MARK: - Sort Change Handler
    private func handleSortChange(oldValue: SortOption?, newValue: SortOption?) {
        guard let newValue = newValue else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if newValue == .nearby {
            if userLocationManager.savedLocation != nil {
                // Location already available
                return
            } else {
                let authStatus = CLLocationManager().authorizationStatus
                if authStatus == .notDetermined {
                    showingLocationPermissionAlert = true
                    pendingNearbySortRequest = true
                    sortBy = oldValue
                } else if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
                    requestLocationPermission()
                    pendingNearbySortRequest = true
                } else {
                    // Permission denied
                    sortBy = oldValue
                }
            }
        }
    }
    
    // MARK: - Location Permission Request
    private func requestLocationPermission() {
        userLocationManager.requestCurrentLocation { result in
            Task { @MainActor in
                switch result {
                case .success:
                    if pendingNearbySortRequest {
                        sortBy = .nearby
                        pendingNearbySortRequest = false
                    }
                case .failure:
                    pendingNearbySortRequest = false
                }
            }
        }
    }
    
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Show loading indicator when debouncing search
                if searchText != debouncedSearchText && !searchText.isEmpty {
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
                        debouncedSearchText = ""
                        searchTask?.cancel()
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
                withAnimation(.easeInOut(duration: AppConstants.standardAnimationDuration)) {
                    sortBy = .date
                }
            }

            FilterButton(
                title: "PRICE",
                isSelected: sortBy == .price
            ) {
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
        if let savedLocation = userLocationManager.savedLocation {
            let cityName = savedLocation.name.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? savedLocation.name
            return cityName.uppercased()
        }
        return "NEARBY"
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if eventViewModel.isLoading && eventViewModel.events.isEmpty {
                        loadingView
                    } else if filteredEvents.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(filteredEvents) { event in
                            NavigationLink(value: NavigationDestination.eventDetail(event)) {
                                EventRow(
                                    event: event,
                                    bookmarkManager: bookmarkManager,
                                    showingSignInAlert: $showingSignInAlert,
                                    namespace: heroNamespace
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .refreshable {
                await eventViewModel.refreshEvents()
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
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No events found")
                .appCard()
                .foregroundColor(.gray)
            
            if !debouncedSearchText.isEmpty {
                Text("Try adjusting your search")
                    .appSecondary()
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(.top, 40)
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(AppState().eventViewModel)
            .environmentObject(AppState().bookmarkManager)
            .preferredColorScheme(.dark)
    }
}
