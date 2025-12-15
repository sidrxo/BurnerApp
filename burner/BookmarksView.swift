import SwiftUI
import Kingfisher

struct BookmarksView: View {
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var onboardingManager: OnboardingManager
    @Environment(\.heroNamespace) private var heroNamespace
    @State private var searchText = ""
    @State private var showingSignInAlert = false
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
        VStack(spacing: 0) {
            // Header Section
            HStack {
                Text("Saves")
                    .appPageHeader()
                    .foregroundColor(.white)
                    .padding(.bottom, 2)

                Spacer()

                ZStack {
                    Rectangle()
                        .fill(.black)
                        .frame(width: 38, height: 38)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 14)
            .padding(.bottom, 30)

            if !bookmarkManager.bookmarkedEvents.isEmpty {

            }
            
            // --- Content Switcher with Animation ---
            Group {
                if bookmarkManager.isLoading {
                    loadingView
                } else if bookmarkManager.bookmarkedEvents.isEmpty {
                    emptyStateView
                } else {
                    bookmarksList
                }
            }
            .animation(.easeInOut(duration: 0.3), value: bookmarkManager.isLoading)
            // ---------------------------------------
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showingSignInAlert {
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
        }
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
            Image("bookmark")
                .resizable()
                .scaledToFit()
                .frame(height: 140) // ← fixed height
                .frame(maxWidth: .infinity) // center horizontally
                .padding(.bottom, 30)
            
            VStack(spacing: 8) {
                TightHeaderText("SAVE FOR", "LATER", alignment: .center)
                    .frame(maxWidth: .infinity)

                Text("Tap \(Image(systemName: "heart")) on any event to save it here.")
                    .appCard()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            BurnerButton("BROWSE EVENTS", style: .primary, maxWidth: 200) {
                coordinator.selectTab(.explore)
            }
            .buttonStyle(PlainButtonStyle())
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
                    Button {
                        // Use a simple animation wrapper for navigation if needed,
                        // but the list deletion animation is the primary focus.
                        coordinator.navigate(to: .eventDetail(event.id ?? ""), in: .bookmarks)
                    } label: {
                        EventRow(
                            event: event,
                            bookmarkManager: bookmarkManager,
                            showingSignInAlert: $showingSignInAlert,
                            namespace: heroNamespace
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    // IMPORTANT: Apply the transition/animation to the row itself.
                    // When the item is removed from the array, this transition is used.
                    // We use .move(edge: .leading) to slide it out/up and .opacity to fade it.
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    
                    // Essential for tracking which row is being removed
                    .id(event.id)
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color.black)
        // Apply the animation to the entire ScrollView content when the list changes.
        // This makes the remaining items smoothly move up into the removed item's space.
        .animation(.easeInOut(duration: 0.3), value: bookmarkManager.bookmarkedEvents.count)
    }
}

// MARK: - Preview
#Preview {
    BookmarksView()
        .environmentObject(AppState().bookmarkManager)
        .preferredColorScheme(.dark)
}
