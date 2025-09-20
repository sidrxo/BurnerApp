//
//  ExploreView.swift
//  burner
//
//  Created by Sid Rao on 03/09/2025.
//

import SwiftUI
import Kingfisher

struct ExploreView: View {
    @StateObject private var eventViewModel = EventViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: ExploreFilter = .trending
    
    var filteredEvents: [Event] {
        var events = eventViewModel.events
        
        // Apply search filter
        if !searchText.isEmpty {
            events = events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.venue.localizedCaseInsensitiveContains(searchText) ||
                event.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply sorting based on filter
        switch selectedFilter {
        case .trending:
            events = events.sorted { first, second in
                if first.isFeatured && !second.isFeatured { return true }
                if !first.isFeatured && second.isFeatured { return false }
                return first.ticketsSold > second.ticketsSold
            }
        case .nearYou:
            events = events.filter { $0.date > Date() }
                .sorted { $0.date < $1.date }
        case .popular:
            events = events.sorted { $0.ticketsSold > $1.ticketsSold }
        case .new:
            events = events.filter { $0.date > Date() }
                .sorted { $0.date > $1.date }
        case .categories:
            events = events.sorted { $0.venue < $1.venue }
        }
        
        return events
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
        VStack(spacing: 16) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .appFont(size: 16, weight: .medium)
                    .foregroundColor(.gray)
                
                TextField("Search for an event, artist or venue", text: $searchText)
                    .appFont(size: 16)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
        .background(Color.black)
    }
    
    private var filtersSection: some View {
        HStack(spacing: 12) {
            FilterButton(title: "DATE", isSelected: false) {
                // Handle date filter
            }
            
            FilterButton(title: "PRICE", isSelected: false) {
                // Handle price filter
            }
            
            LocationFilterButton(location: "LONDON") {
                // Handle location filter
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
                        ForEach(filteredEvents.prefix(10)) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventListItem(event: event)
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

// MARK: - Supporting Views


struct LocationFilterButton: View {
    let location: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "location")
                    .appFont(size: 14, weight: .medium)
                
                Text(location)
                    .appFont(size: 14, weight: .semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
        }
    }
}

struct EventListItem: View {
    let event: Event
    @State private var isFavorited = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image with Kingfisher
            KFImage(URL(string: event.imageUrl))
                .placeholder {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray4))
                }
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(event.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(.gray)
                
                Text(event.venue)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Favorite Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFavorited.toggle()
                }
            }) {
                Image(systemName: isFavorited ? "bookmark.fill" : "bookmark")
                    .appFont(size: 18, weight: .medium)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct EmptyEventsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "calendar.badge.exclamationmark" : "magnifyingglass")
                .appFont(size: 60, weight: .light)
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Events Found" : "No Search Results")
                    .font(.appTitle3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(searchText.isEmpty ?
                     "There are no events available at the moment." :
                     "Try searching with different keywords.")
                    .font(.appSubheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
    }
}

// MARK: - Supporting Models

enum ExploreFilter: CaseIterable {
    case trending, nearYou, popular, new, categories
    
    var displayName: String {
        switch self {
        case .trending: return "Trending"
        case .nearYou: return "Upcoming"
        case .popular: return "Popular"
        case .new: return "New"
        case .categories: return "By Venue"
        }
    }
    
    var icon: String {
        switch self {
        case .trending: return "flame"
        case .nearYou: return "clock"
        case .popular: return "star"
        case .new: return "sparkles"
        case .categories: return "building.2"
        }
    }
}


// MARK: - Preview

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .preferredColorScheme(.dark)
    }
}

