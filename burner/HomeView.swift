import SwiftUI
import Kingfisher

struct HomeView: View {
    // ✅ Use shared ViewModels from environment instead of creating new instances
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    @State private var searchText = ""
    @State private var selectedEvent: Event? = nil

    var featuredEvent: Event? {
        eventViewModel.events.filter { $0.isFeatured }.first
    }
    
    var secondFeaturedEvent: Event? {
        let featuredEvents = eventViewModel.events.filter { $0.isFeatured }
        return featuredEvents.count > 1 ? featuredEvents[1] : nil
    }
    
    var popularEvents: [Event] {
        eventViewModel.events.filter { !$0.isFeatured }.prefix(4).map { $0 }
    }
    
    var upcomingEvents: [Event] {
        eventViewModel.events.filter { $0.date > Date() }.prefix(4).map { $0 }
    }
    
    var allEvents: [Event] {
        Array(eventViewModel.events.prefix(6))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HeaderSection(title: "Explore")
                    
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
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            if let featured = featuredEvent {
                NavigationLink(value: featured) {
                    FeaturedHeroCard(event: featured, bookmarkManager: bookmarkManager)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .buttonStyle(PlainButtonStyle())
            }
                                
            if !popularEvents.isEmpty {
                EventSection(
                    title: "Popular",
                    events: popularEvents,
                    bookmarkManager: bookmarkManager
                )
            }
            
            if !upcomingEvents.isEmpty {
                EventSection(
                    title: "Upcoming",
                    events: upcomingEvents,
                    bookmarkManager: bookmarkManager
                )
            }
            
            if let secondFeatured = secondFeaturedEvent {
                NavigationLink(value: secondFeatured) {
                    FeaturedHeroCard(event: secondFeatured, bookmarkManager: bookmarkManager)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if !allEvents.isEmpty {
                EventSection(
                    title: "All Events",
                    events: allEvents,
                    bookmarkManager: bookmarkManager
                )
            }
        }
    }
}

// MARK: - Reusable Event Section Component
struct EventSection: View {
    let title: String
    let events: [Event]
    let bookmarkManager: BookmarkManager
    let showViewAllButton: Bool
    let onViewAllTapped: (() -> Void)?
    
    init(
        title: String,
        events: [Event],
        bookmarkManager: BookmarkManager,
        showViewAllButton: Bool = true,
        onViewAllTapped: (() -> Void)? = nil
    ) {
        self.title = title
        self.events = events
        self.bookmarkManager = bookmarkManager
        self.showViewAllButton = showViewAllButton
        self.onViewAllTapped = onViewAllTapped
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
                    Button(action: {
                        onViewAllTapped?()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.appIcon)
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Event List
            LazyVStack(spacing: 12) {
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        UnifiedEventRow(
                            event: event,
                            bookmarkManager: bookmarkManager
                        )
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState().eventViewModel)
            .environmentObject(AppState().bookmarkManager)
            .preferredColorScheme(.dark)
    }
}

// MARK: - Event Equatable & Hashable (for NavigationLink value)
extension Event: Hashable {
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
