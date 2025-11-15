import SwiftUI
import FirebaseAuth
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        NavigationCoordinatorView {
            ZStack {
                // Home Tab
                NavigationStack(path: $coordinator.homePath) {
                    ExploreView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
                .opacity(coordinator.selectedTab == .home ? 1 : 0)
                .zIndex(coordinator.selectedTab == .home ? 1 : 0)

                // Explore Tab
                NavigationStack(path: $coordinator.explorePath) {
                    SearchView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
                .opacity(coordinator.selectedTab == .explore ? 1 : 0)
                .zIndex(coordinator.selectedTab == .explore ? 1 : 0)

                // Tickets Tab
                NavigationStack(path: $coordinator.ticketsPath) {
                    TicketsView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
                .opacity(coordinator.selectedTab == .tickets ? 1 : 0)
                .zIndex(coordinator.selectedTab == .tickets ? 1 : 0)

                // Settings Tab
                NavigationStack(path: $coordinator.settingsPath) {
                    SettingsView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
                .opacity(coordinator.selectedTab == .settings ? 1 : 0)
                .zIndex(coordinator.selectedTab == .settings ? 1 : 0)
                
                // Custom tab bar overlay
                VStack {
                    Spacer()
                    if shouldShowTabBar {
                        CustomTabBar()
                            .transition(.move(edge: .bottom))
                    }
                }
                .zIndex(100)
                .ignoresSafeArea(.keyboard)
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
