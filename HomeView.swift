import SwiftUI
import Kingfisher

struct HomeView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @State private var searchText = ""
    @State private var selectedEvent: Event? = nil

    var featuredEvent: Event? {
        eventViewModel.events.filter { $0.isFeatured }.first
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

// MARK: - Featured Hero Card
struct FeaturedHeroCard: View {
    let event: Event
    @State private var isBookmarked = false
    
    var body: some View {
        ZStack {
            KFImage(URL(string: event.imageUrl))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .resizable()
                .scaledToFill()
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack {
                HStack {
                    Spacer()
                    Text(event.venue.uppercased())
                        .appFont(size: 12, weight: .bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                }
                .padding(.top, 20)
                .padding(.trailing, 20)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.name)
                                .appFont(size: 32, weight: .black)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(event.date.formatted(.dateTime.weekday().day().month())) • \(event.venue)")
                                .appFont(size: 16, weight: .medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("From £\(String(format: "%.2f", event.price))")
                                .appFont(size: 16, weight: .bold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        Spacer()
                        
                        Button(action: { isBookmarked.toggle() }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .appFont(size: 20, weight: .medium)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "hand.thumbsup")
                                .appFont(size: 20, weight: .medium)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "hand.thumbsdown")
                                .appFont(size: 20, weight: .medium)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
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
