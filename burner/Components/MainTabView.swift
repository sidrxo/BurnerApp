import SwiftUI
import FirebaseAuth
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Namespace private var exploreHeroNamespace
    @Namespace private var searchHeroNamespace
    @Namespace private var bookmarksHeroNamespace
    @Namespace private var ticketsHeroNamespace
    
    // ✅ FIX: Calculate transition for the SPECIFIC tab instance
    // This ensures that an outgoing view gets the correct removal transition
    // regardless of what its previous state was.
    private func getTransition(for tab: AppTab) -> AnyTransition {
        let selected = coordinator.selectedTab
        let previous = coordinator.previousTab
        
        // CASE A: I am the Outgoing View (I am 'tab', but selected is someone else)
        if selected != tab {
            if selected.rawValue > tab.rawValue {
                return .move(edge: .leading) // We are moving Forward, so I Exit Left
            } else {
                return .move(edge: .trailing) // We are moving Backward, so I Exit Right
            }
        }
        // CASE B: I am the Incoming View (I am 'tab', and I am selected)
        else {
            if tab.rawValue > previous.rawValue {
                return .move(edge: .trailing) // We came from Left, so I Enter from Right
            } else {
                return .move(edge: .leading) // We came from Right, so I Enter from Left
            }
        }
    }

    var body: some View {
        NavigationCoordinatorView {
            ZStack {
                // EXPLORE (Index 0)
                if coordinator.selectedTab == .explore {
                    NavigationStack(path: $coordinator.explorePath) {
                        ExploreView()
                            .environment(\.heroNamespace, exploreHeroNamespace)
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                NavigationDestinationBuilder(destination: destination)
                                    .environment(\.heroNamespace, exploreHeroNamespace)
                            }
                    }
                    .transition(getTransition(for: .explore))
                    .zIndex(coordinator.selectedTab == .explore ? 1 : 0)
                }

                // SEARCH (Index 1)
                if coordinator.selectedTab == .search {
                    NavigationStack(path: $coordinator.searchPath) {
                        SearchView()
                            .environment(\.heroNamespace, searchHeroNamespace)
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                NavigationDestinationBuilder(destination: destination)
                                    .environment(\.heroNamespace, searchHeroNamespace)
                            }
                    }
                    .transition(getTransition(for: .search))
                    .zIndex(coordinator.selectedTab == .search ? 1 : 0)
                }

                // BOOKMARKS (Index 2)
                if coordinator.selectedTab == .bookmarks {
                    NavigationStack(path: $coordinator.bookmarksPath) {
                        BookmarksView()
                             .environment(\.heroNamespace, bookmarksHeroNamespace)
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                NavigationDestinationBuilder(destination: destination)
                                    .environment(\.heroNamespace, bookmarksHeroNamespace)
                            }
                    }
                    .transition(getTransition(for: .bookmarks))
                    .zIndex(coordinator.selectedTab == .bookmarks ? 1 : 0)
                }
                
                // TICKETS (Index 3)
                if coordinator.selectedTab == .tickets {
                    NavigationStack(path: $coordinator.ticketsPath) {
                        TicketsView()
                            .environment(\.heroNamespace, ticketsHeroNamespace)
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                NavigationDestinationBuilder(destination: destination)
                                    .environment(\.heroNamespace, ticketsHeroNamespace)
                            }
                    }
                    .transition(getTransition(for: .tickets))
                    .zIndex(coordinator.selectedTab == .tickets ? 1 : 0)
                }

                VStack {
                    Spacer()
                    CustomTabBar()
                        .offset(y: shouldShowTabBar ? 0 : 100)
                        .opacity(shouldShowTabBar ? 1 : 0)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: shouldShowTabBar)
                .zIndex(100)
                .ignoresSafeArea(.keyboard)
            }
            // ✅ IMPORTANT: Animate based on the atomic state change
            .animation(.easeInOut(duration: 0.25), value: coordinator.selectedTab)
        }
    }
    
    private var shouldShowTabBar: Bool {
        guard !coordinator.shouldHideTabBar else {
            return false
        }
        
        switch coordinator.selectedTab {
        case .explore:
            return coordinator.explorePath.count == 0
        case .search:
            return coordinator.searchPath.count == 0
        case .bookmarks:
            return coordinator.bookmarksPath.count == 0
        case .tickets:
            return coordinator.ticketsPath.count == 0
        }
    }
}

struct CustomTabBar: View {
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        HStack {
            // 0: Explore
            TabBarButton(
                icon: "homeicon",
                isSelected: coordinator.selectedTab == .explore
            ) {
                coordinator.selectTab(.explore)
            }

            Spacer()

            // 1: Search
            TabBarButton(
                icon: "searchicon",
                isSelected: coordinator.selectedTab == .search
            ) {
                coordinator.selectTab(.search)
            }

            Spacer()
            
            // 2: Bookmarks
            TabBarButton(
                icon: "heart",
                isSelected: coordinator.selectedTab == .bookmarks
            ) {
                coordinator.selectTab(.bookmarks)
            }

            Spacer()

            // 3: Tickets
            TabBarButton(
                icon: "ticketicon",
                isSelected: coordinator.selectedTab == .tickets,
                rotationDegrees: 90
            ) {
                coordinator.selectTab(.tickets)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .background(Color.black)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    var rotationDegrees: Double = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(rotationDegrees))
                    .frame(width: 24, height: 24)
                    .opacity(isSelected ? 0 : 1)
                
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotationDegrees))
                    .frame(width: 24, height: 24)
                    .scaleEffect(isSelected ? 1.0 : 0.5)
                    .opacity(isSelected ? 1.0 : 0.0)
            }
            .frame(width: 44, height: 30)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
