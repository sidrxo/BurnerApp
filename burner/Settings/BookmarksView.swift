import SwiftUI
import Kingfisher

struct BookmarksView: View {
    // Use @EnvironmentObject instead of @StateObject
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
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
                SettingsHeaderSection(title: "Bookmarks")
                    .padding(.horizontal, 20)
                    .padding(.top, 20)


                
                if !bookmarkManager.bookmarkedEvents.isEmpty {
                    
                }
                
                if bookmarkManager.isLoading {
                    loadingView
                } else if bookmarkManager.bookmarkedEvents.isEmpty {
                    emptyStateView
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading bookmarks...")
                .appBody()
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .appHero()
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Bookmarks Yet")
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Text("Bookmark events you're interested in to see them here")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Browse Events") {
                // Dismiss bookmarks view to return to settings
                dismiss()
            }
            .appBody()
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
    
    // MARK: - Bookmarks List
    private var bookmarksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredBookmarks) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        UnifiedEventRow(
                            event: event,
                            bookmarkManager: bookmarkManager
                        )
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
    @ObservedObject var bookmarkManager: BookmarkManager
    @State private var showingRemoveAlert = false

    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                // Event Image
                KFImage(URL(string: event.imageUrl))
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .appSectionHeader()
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
                        .appBody()
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(event.venue)
                        .appSecondary()
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .appCaption()
                            .foregroundColor(.gray)

                        Text((event.startTime ?? Date()).formatted(.dateTime.weekday(.abbreviated).day().month()))
                            .appCaption()
                            .foregroundColor(.gray)
                    }

                    Text("£\(String(format: "%.2f", event.price))")
                        .appSecondary()
                        .foregroundColor(.white)
                }

                Spacer()

                // Remove Bookmark Button
                Button(action: {
                    showingRemoveAlert = true
                }) {
                    Image(systemName: "bookmark.fill")
                        .appBody()
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if showingRemoveAlert {
                CustomAlertView(
                    title: "Remove Bookmark",
                    description: "Are you sure you want to remove this event from your bookmarks?",
                    cancelAction: { showingRemoveAlert = false },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        showingRemoveAlert = false
                        Task {
                            await bookmarkManager.toggleBookmark(for: event)
                        }
                    },
                    primaryActionTitle: "Remove",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    BookmarksView()
        .environmentObject(AppState().bookmarkManager)
        .preferredColorScheme(.dark)
}
