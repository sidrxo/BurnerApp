import SwiftUI
import Kingfisher

// MARK: - Filtered Events View
struct FilteredEventsView: View {
    let title: String
    let events: [Event]
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var onboardingManager: OnboardingManager
    @Environment(\.heroNamespace) private var heroNamespace
    @State private var showingSignInAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            if events.isEmpty {
                emptyStateView
            } else {
                HeaderSection(title: title, includeTopPadding: false, includeHorizontalPadding: false)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(events) { event in
                            NavigationLink(value: NavigationDestination.eventDetail(event.id ?? "")) {
                                EventRow(
                                    event: event,
                                    bookmarkManager: bookmarkManager,
                                    showingSignInAlert: $showingSignInAlert,
                                    namespace: heroNamespace
                                )
                            }
                            .buttonStyle(.noHighlight)
                        }
                    }
                    .padding(.bottom, 100)
                }
                
            }
            
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {

            VStack(spacing: 8) {
                Text("No Events Found")
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Text("No events available in this category")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}
