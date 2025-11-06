import SwiftUI
import Kingfisher
import Combine
import FirebaseFirestore

// MARK: - Optimized ExploreView
struct ExploreView: View {
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var coordinator: NavigationCoordinator
    @StateObject private var viewModel = ExploreViewModel()

    @State private var searchText = ""
    @State private var sortBy: SortOption = .date
    @FocusState private var isSearchFocused: Bool

    enum SortOption: String {
        case date = "date"
        case price = "price"
    }
    
    var body: some View {
        NavigationStack {
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
                Task {
                    await viewModel.changeSort(to: newValue.rawValue, searchText: searchText)
                }
            }
            .onChange(of: coordinator.shouldFocusSearchBar) { _, shouldFocus in
                if shouldFocus {
                    isSearchFocused = true
                }
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

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
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
                            NavigationLink(destination: EventDetailView(event: event)) {
                                UnifiedEventRow(
                                    event: event,
                                    bookmarkManager: bookmarkManager
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                // Load more when reaching last item
                                if event.id == viewModel.events.last?.id {
                                    Task {
                                        await viewModel.loadMoreEvents(
                                            sortBy: sortBy.rawValue,
                                            searchText: searchText
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Loading more indicator
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                                    .padding(.vertical, 20)
                                Spacer()
                            }
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
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - ExploreViewModel (Performance Optimized)
@MainActor
class ExploreViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    private var hasMoreEvents = true
    private var lastDocument: Date?
    private var currentSearchText = ""
    private var searchCache: [String: [Event]] = [:]

    private let eventRepository = OptimizedEventRepository()
    private var searchCancellable: AnyCancellable?
    private let searchSubject = PassthroughSubject<(String, String), Never>()
    
    init() {
        setupSearchDebouncing()
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
            let fetchedEvents = try await eventRepository.fetchUpcomingEvents(
                sortBy: sortBy,
                limit: 20
            )

            events = fetchedEvents
            lastDocument = fetchedEvents.last?.startTime
            hasMoreEvents = fetchedEvents.count >= 20

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
            let fetchedEvents = try await eventRepository.fetchUpcomingEvents(
                sortBy: sortBy,
                limit: 20,
                startAfter: lastDocument
            )
            
            events.append(contentsOf: fetchedEvents)
            lastDocument = fetchedEvents.last?.startTime
            hasMoreEvents = fetchedEvents.count >= 20
            
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
        if searchText.isEmpty {
            await loadInitialEvents(sortBy: sortBy)
        } else {
            await performSearch(searchText: searchText, sortBy: sortBy)
        }
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
        var query = db.collection("events")
            .whereField("startTime", isGreaterThan: Date()) // Changed from "date"
            .order(by: sortBy)
            .limit(to: limit)
        
        if let startAfter = startAfter {
            query = query.start(after: [startAfter])
        }
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { doc in
            var event = try? doc.data(as: Event.self)
            event?.id = doc.documentID
            return event
        }
    }

    func searchEvents(
        searchText: String,
        sortBy: String = "startTime",
        limit: Int = 50
    ) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("startTime", isGreaterThan: Date()) // Changed from "date"
            .order(by: sortBy)
            .limit(to: limit)
            .getDocuments()
        
        let allEvents = snapshot.documents.compactMap { doc -> Event? in
            var event = try? doc.data(as: Event.self)
            event?.id = doc.documentID
            return event
        }
        
        // Filter client-side (consider Algolia for production)
        let searchLower = searchText.lowercased()
        return allEvents.filter { event in
            event.name.lowercased().contains(searchLower) ||
            event.venue.lowercased().contains(searchLower) ||
            (event.description?.lowercased().contains(searchLower) ?? false)
        }
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

// MARK: - Preview
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(AppState().bookmarkManager)
            .preferredColorScheme(.dark)
    }
}
