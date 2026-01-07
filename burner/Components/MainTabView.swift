import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Namespace private var exploreHeroNamespace
    @Namespace private var searchHeroNamespace
    @Namespace private var bookmarksHeroNamespace
    @Namespace private var ticketsHeroNamespace

    var body: some View {
        NavigationCoordinatorView {
            ZStack {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        NavigationStack(path: $coordinator.explorePath) {
                            ExploreView()
                                .environment(\.heroNamespace, exploreHeroNamespace)
                                .navigationDestination(for: NavigationDestination.self) { destination in
                                    NavigationDestinationBuilder(destination: destination)
                                        .environment(\.heroNamespace, exploreHeroNamespace)
                                }
                        }
                        .frame(width: geometry.size.width)
                        .tag(AppTab.explore)

                        NavigationStack(path: $coordinator.searchPath) {
                            SearchView()
                                .environment(\.heroNamespace, searchHeroNamespace)
                                .navigationDestination(for: NavigationDestination.self) { destination in
                                    NavigationDestinationBuilder(destination: destination)
                                        .environment(\.heroNamespace, searchHeroNamespace)
                                }
                        }
                        .frame(width: geometry.size.width)
                        .tag(AppTab.search)

                        NavigationStack(path: $coordinator.bookmarksPath) {
                            BookmarksView()
                                 .environment(\.heroNamespace, bookmarksHeroNamespace)
                                .navigationDestination(for: NavigationDestination.self) { destination in
                                    NavigationDestinationBuilder(destination: destination)
                                        .environment(\.heroNamespace, bookmarksHeroNamespace)
                                }
                        }
                        .frame(width: geometry.size.width)
                        .tag(AppTab.bookmarks)

                        NavigationStack(path: $coordinator.ticketsPath) {
                            TicketsView()
                                .environment(\.heroNamespace, ticketsHeroNamespace)
                                .navigationDestination(for: NavigationDestination.self) { destination in
                                    NavigationDestinationBuilder(destination: destination)
                                        .environment(\.heroNamespace, ticketsHeroNamespace)
                                }
                        }
                        .frame(width: geometry.size.width)
                        .tag(AppTab.tickets)
                    }
                    .offset(x: -CGFloat(coordinator.selectedTab.rawValue) * geometry.size.width)
                    .animation(.easeInOut(duration: 0.3), value: coordinator.selectedTab)
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
        }
    }

    private var shouldShowTabBar: Bool {
        guard !coordinator.shouldHideTabBar else {
            return false
        }
        
        // Simplified check: tab bar is visible only when at the root of the current tab's path
        switch coordinator.selectedTab {
        case .explore:
            return coordinator.explorePath.isEmpty
        case .search:
            return coordinator.searchPath.isEmpty
        case .bookmarks:
            return coordinator.bookmarksPath.isEmpty
        case .tickets:
            return coordinator.ticketsPath.isEmpty
        }
    }
}

struct CustomTabBar: View {
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        HStack {
            TabBarButton(
                icon: "homeicon",
                isSelected: coordinator.selectedTab == .explore
            ) {
                coordinator.selectTab(.explore)
            }

            Spacer()

            TabBarButton(
                icon: "searchicon",
                isSelected: coordinator.selectedTab == .search
            ) {
                coordinator.selectTab(.search)
            }

            Spacer()
            
            TabBarButton(
                icon: "heart",
                isSelected: coordinator.selectedTab == .bookmarks
            ) {
                coordinator.selectTab(.bookmarks)
            }

            Spacer()

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
