import SwiftUI
import FirebaseAuth
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("useWalletView") private var useWalletView = true

    var body: some View {
        NavigationCoordinatorView {
            TabView(selection: $appState.navigationCoordinator.selectedTab) {
                // Home Tab
                NavigationStack(path: $appState.navigationCoordinator.homePath) {
                    ExploreView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
                .tag(AppTab.home)
                .tabItem { EmptyView() }

                // Explore Tab
                NavigationStack(path: $appState.navigationCoordinator.explorePath) {
                    SearchView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
                .tag(AppTab.explore)
                .tabItem { EmptyView() }

                // Tickets Tab
                NavigationStack(path: $appState.navigationCoordinator.ticketsPath) {
                    if useWalletView {
                        TicketsView()
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                NavigationDestinationBuilder(destination: destination)
                            }
                    } else {
                        TicketsWalletView()
                            .navigationDestination(for: NavigationDestination.self) { destination in
                                NavigationDestinationBuilder(destination: destination)
                            }
                    }
                }
                .tag(AppTab.tickets)
                .tabItem { EmptyView() }

                // Settings Tab
                NavigationStack(path: $appState.navigationCoordinator.settingsPath) {
                    SettingsView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
                .tag(AppTab.settings)
                .tabItem { EmptyView() }
            }
            .tabViewStyle(.automatic)
            .overlay(alignment: .bottom) {
                // Custom tab bar overlay - only show when at root of any tab
                if shouldShowTabBar {
                    CustomTabBar()
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }
    
    // FIXED: Simplified tab bar visibility logic
    private var shouldShowTabBar: Bool {
        // Don't show if explicitly hidden
        guard !appState.navigationCoordinator.shouldHideTabBar else {
            return false
        }
        
        // Show only at root of each tab
        let coordinator = appState.navigationCoordinator
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
        .padding(.vertical, 20)
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
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .rotationEffect(.degrees(rotationDegrees))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
