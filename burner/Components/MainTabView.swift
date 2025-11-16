import SwiftUI
import FirebaseAuth
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Namespace private var homeHeroNamespace
    @Namespace private var exploreHeroNamespace
    @Namespace private var ticketsHeroNamespace
    @Namespace private var settingsHeroNamespace

    var body: some View {
        NavigationCoordinatorView {
            TabView(selection: $coordinator.selectedTab) {
                // Home Tab
                NavigationStack(path: $coordinator.homePath) {
                    ExploreView()
                        .environment(\.heroNamespace, homeHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, homeHeroNamespace)
                        }
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)

                // Explore Tab
                NavigationStack(path: $coordinator.explorePath) {
                    SearchView()
                        .environment(\.heroNamespace, exploreHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, exploreHeroNamespace)
                        }
                }
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(AppTab.explore)

                // Tickets Tab
                NavigationStack(path: $coordinator.ticketsPath) {
                    TicketsView()
                        .environment(\.heroNamespace, ticketsHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, ticketsHeroNamespace)
                        }
                }
                .tabItem {
                    Label("Tickets", systemImage: "ticket")
                }
                .tag(AppTab.tickets)

                // Settings Tab
                NavigationStack(path: $coordinator.settingsPath) {
                    SettingsView()
                        .environment(\.heroNamespace, settingsHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, settingsHeroNamespace)
                        }
                }
                .tabItem {
                    Label("Settings", systemImage: "person")
                }
                .tag(AppTab.settings)
            }
            .tint(.white)
            .preferredColorScheme(.dark)
            .overlay(alignment: .bottom) {
                if shouldShowTabBar {
                    CustomTabBar()
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }
    
    private var shouldShowTabBar: Bool {
        guard !coordinator.shouldHideTabBar else {
            return false
        }
        
        switch coordinator.selectedTab {
        case .home:
            return coordinator.homePath.count == 0
        case .explore:
            return coordinator.explorePath.count == 0
        case .tickets:
            return coordinator.ticketsPath.count == 0
        case .settings:
            return coordinator.settingsPath.count == 0
        }
    }
}

struct CustomTabBar: View {
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        HStack {
            TabBarButton(
                icon: "house",
                isSelected: coordinator.selectedTab == .home
            ) {
                coordinator.selectTab(.home)
            }

            Spacer()

            TabBarButton(
                icon: "magnifyingglass",
                isSelected: coordinator.selectedTab == .explore
            ) {
                coordinator.selectTab(.explore)
            }

            Spacer()

            TabBarButton(
                icon: "ticket",
                isSelected: coordinator.selectedTab == .tickets,
                rotationDegrees: 90
            ) {
                coordinator.selectTab(.tickets)
            }

            Spacer()

            TabBarButton(
                icon: "person",
                isSelected: coordinator.selectedTab == .settings
            ) {
                coordinator.selectTab(.settings)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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
            Image(systemName: icon)
                .appSectionHeader()
                .foregroundColor(isSelected ? .white : .gray)
                .rotationEffect(.degrees(rotationDegrees))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
