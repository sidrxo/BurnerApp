import SwiftUI
import Kingfisher

struct HomeView: View {
    @StateObject private var eventViewModel = EventViewModel()
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
                    HeaderSection()
                    
                    if let featured = featuredEvent {
                        NavigationLink(value: featured) {
                            FeaturedHeroCard(event: featured)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                                        
                    PopularEventsSection(events: popularEvents)
                    UpcomingEventsSection(events: upcomingEvents)
                    
                    if let secondFeatured = secondFeaturedEvent {
                        NavigationLink(value: secondFeatured) {
                            FeaturedHeroCard(event: secondFeatured)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    AllEventsSection(events: allEvents)
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

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        HStack {
            Text("Make plans")
                .appFont(size: 28, weight: .bold)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 30)
    }
}

// MARK: - Popular Events Section
struct PopularEventsSection: View {
    let events: [Event]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular")
                    .appFont(size: 24, weight: .bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .appFont(size: 16, weight: .medium)
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
                        EventListRow(event: event)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming")
                    .appFont(size: 24, weight: .bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .appFont(size: 16, weight: .medium)
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
                        EventListRow(event: event)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Events")
                    .appFont(size: 24, weight: .bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .appFont(size: 16, weight: .medium)
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
                        EventListRow(event: event)
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
    @State private var isBookmarked = false
    
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
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(event.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(.gray)
                
                Text(event.venue)
                    .appFont(size: 14, weight: .regular)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: { isBookmarked.toggle() }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .appFont(size: 18, weight: .medium)
                    .foregroundColor(.gray)
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
