import SwiftUI
import Kingfisher

struct FavoritesView: View {
    @StateObject private var bookmarkManager = BookmarkManager()
    @State private var searchText = ""
    
    private var filteredBookmarks: [Event] {
        if searchText.isEmpty {
            return bookmarkManager.bookmarkedEvents
        } else {
            return bookmarkManager.bookmarkedEvents.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.venue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                HeaderSection(title: "Bookmarks")
                
                if !bookmarkManager.bookmarkedEvents.isEmpty {
                    searchSection
                }
                
                if bookmarkManager.isLoading {
                    loadingView
                } else if bookmarkManager.bookmarkedEvents.isEmpty {
                    emptyStateView
                } else if filteredBookmarks.isEmpty {
                    emptySearchView
                } else {
                    bookmarksList
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .appFont(size: 16, weight: .medium)
                .foregroundColor(.gray)
            
            TextField("Search favorites", text: $searchText)
                .appFont(size: 16)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading favorites...")
                .appFont(size: 16)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Bookmarks Yet")
                    .appFont(size: 22, weight: .semibold)
                    .foregroundColor(.white)
                
                Text("Bookmark events you're interested in to see them here")
                    .appFont(size: 16)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Browse Events") {
                // Navigate to home or explore tab
                // You can implement navigation logic here
            }
            .appFont(size: 17, weight: .semibold)
            .foregroundColor(.black)
            .frame(maxWidth: 200)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .padding(.bottom, 100)
    }
    
    // MARK: - Empty Search View
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .appFont(size: 18, weight: .semibold)
                    .foregroundColor(.white)
                
                Text("Try adjusting your search terms")
                    .appFont(size: 16)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .padding(.bottom, 100)
    }
    
    // MARK: - Bookmarks List
    private var bookmarksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredBookmarks) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        BookmarkListItem(
                            event: event,
                            bookmarkManager: bookmarkManager
                        )
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color.black)
    }
}

// MARK: - Bookmark List Item
struct BookmarkListItem: View {
    let event: Event
    let bookmarkManager: BookmarkManager
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            KFImage(URL(string: event.imageUrl))
                .placeholder {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        )
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
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(event.venue)
                    .appFont(size: 14)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(event.date.formatted(.dateTime.weekday(.abbreviated).day().month()))
                        .appFont(size: 12)
                        .foregroundColor(.gray)
                }
                
                Text("£\(String(format: "%.2f", event.price))")
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Remove Bookmark Button
            Button(action: {
                showingRemoveAlert = true
            }) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Remove Bookmark", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    await bookmarkManager.toggleBookmark(for: event)
                }
            }
        } message: {
            Text("Are you sure you want to remove this event from your bookmarks?")
        }
    }
}

// MARK: - Preview
#Preview {
    FavoritesView()
        .preferredColorScheme(.dark)
}
