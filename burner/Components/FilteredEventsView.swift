import SwiftUI
import Kingfisher

// MARK: - Filtered Events View
struct FilteredEventsView: View {
    let title: String
    let events: [Event]
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    var body: some View {
        VStack(spacing: 0) {
            if events.isEmpty {
                emptyStateView
            } else {
                SettingsHeaderSection(title: title)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(events) { event in
                            NavigationLink(value: NavigationDestination.eventDetail(event)) {
                                EventRow(
                                    event: event,
                                    bookmarkManager: bookmarkManager
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
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
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.appLargeIcon)
                .foregroundColor(.gray)

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


#Preview {
    NavigationStack {
        FilteredEventsView(
            title: "Techno",
            events: []
        )
        .environmentObject(AppState().bookmarkManager)
    }
    .preferredColorScheme(.dark)
}
