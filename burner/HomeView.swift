import SwiftUI
import Kingfisher

struct HomeView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var bookmarkManager = BookmarkManager()
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
                    
                    if let featured = featuredEvent {
                        NavigationLink(value: featured) {
                            FeaturedHeroCard(event: featured, bookmarkManager: bookmarkManager)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                                        
                    PopularEventsSection(events: popularEvents, bookmarkManager: bookmarkManager)
                    UpcomingEventsSection(events: upcomingEvents, bookmarkManager: bookmarkManager)
                    
                    if let secondFeatured = secondFeaturedEvent {
                        NavigationLink(value: secondFeatured) {
                            FeaturedHeroCard(event: secondFeatured, bookmarkManager: bookmarkManager)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    AllEventsSection(events: allEvents, bookmarkManager: bookmarkManager)
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
            .background(Color.black)
            .onAppear {
                eventViewModel.fetchEvents()
            }
            .refreshable {
                eventViewModel.fetchEvents()
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
    }
}


// MARK: - Popular Events Section
struct PopularEventsSection: View {
    let events: [Event]
    let bookmarkManager: BookmarkManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular")
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .appBody()
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            LazyVStack(spacing: 12) {
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        EventListRow(event: event, bookmarkManager: bookmarkManager)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Upcoming Events Section
struct UpcomingEventsSection: View {
    let events: [Event]
    let bookmarkManager: BookmarkManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming")
                    .appSectionHeader()
                    .appSectionHeader()
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .font(.appIcon)
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            LazyVStack(spacing: 12) {
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        EventListRow(event: event, bookmarkManager: bookmarkManager)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - All Events Section
struct AllEventsSection: View {
    let events: [Event]
    let bookmarkManager: BookmarkManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Events")
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .font(.appIcon)
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            LazyVStack(spacing: 12) {
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        EventListRow(event: event, bookmarkManager: bookmarkManager)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Event List Row
struct EventListRow: View {
    let event: Event
    @ObservedObject var bookmarkManager: BookmarkManager
    
    private var isBookmarked: Bool {
        guard let eventId = event.id else { return false }
        return bookmarkManager.isBookmarked(eventId)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: event.imageUrl))
                .placeholder {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .appBody()
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(event.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .appSecondary()
                    .foregroundColor(.gray)
                
                Text(event.venue)
                    .appSecondary()
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await bookmarkManager.toggleBookmark(for: event)
                }
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.appIcon)
                    .foregroundColor(isBookmarked ? .white : .gray)
                    .scaleEffect(isBookmarked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isBookmarked)
            }
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
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
