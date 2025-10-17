import SwiftUI
import Kingfisher

struct ExploreView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var bookmarkManager = BookmarkManager()
    @State private var searchText = ""
    @State private var sortBy: SortOption = .date
    
    enum SortOption {
        case date
        case price
    }
    
    var filteredEvents: [Event] {
        var events = eventViewModel.events
        
        // First filter out past events (only show future events)
        let currentDate = Date()
        events = events.filter { event in
            event.date > currentDate
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            events = events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.venue.localizedCaseInsensitiveContains(searchText) ||
                event.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply sorting based on selected sort option (lowest to highest)
        switch sortBy {
        case .date:
            events = events.sorted { $0.date < $1.date }
        case .price:
            events = events.sorted { $0.price < $1.price }
        }
        
        return events
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderSection(title: "Search")
                searchSection
                filtersSection
                contentSection
            }
            .navigationBarHidden(true)
            .background(Color.black)
            .onAppear {
                eventViewModel.fetchEvents()
            }
            .refreshable {
                eventViewModel.fetchEvents()
            }
        }
    }
    
    private var searchSection: some View {
        HStack(spacing: 12) {
            // Search Bar with reduced width
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.appIcon)
                    .foregroundColor(.gray)
                
                TextField("Search events", text: $searchText)
                    .appBody()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            
            // Location button
        }
        .padding(.horizontal, 20)
    }
    
    private var filtersSection: some View {
        HStack(spacing: 12) {
            // Date filter button
            FilterButton(
                title: "DATE",
                isSelected: sortBy == .date
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    sortBy = .date
                }
            }
            
            // Price filter button
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
                    if eventViewModel.isLoading {
                        ProgressView("Loading events...")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    } else if filteredEvents.isEmpty {
                        EmptyEventsView(searchText: searchText)
                    } else {
                        ForEach(filteredEvents.prefix(20)) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                UnifiedEventRow(
                                    event: event,
                                    bookmarkManager: bookmarkManager
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct EmptyEventsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
    }
}

// MARK: - Preview

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .preferredColorScheme(.dark)
    }
}
