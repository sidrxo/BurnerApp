import SwiftUI
import FirebaseAuth
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("useWalletView") private var useWalletView = true

    // Computed property to determine if tab bar should be shown
    private var shouldShowTabBar: Bool {
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

    var body: some View {
        NavigationCoordinatorView {
            ZStack {
                // Content based on selected tab
                Group {
                    switch appState.navigationCoordinator.selectedTab {
                    case .home:
                        NavigationStack(path: $appState.navigationCoordinator.homePath) {
                            HomeView()
                                .navigationDestination(for: NavigationDestination.self) { destination in
                                    NavigationDestinationBuilder(destination: destination)
                                }
                                .navigationDestination(for: Event.self) { event in
                                    EventDetailView(event: event)
                                }
                        }

                    case .explore:
                        NavigationStack(path: $appState.navigationCoordinator.explorePath) {
                            ExploreView()
                                .navigationDestination(for: NavigationDestination.self) { destination in
                                    NavigationDestinationBuilder(destination: destination)
                                }
                                .navigationDestination(for: Event.self) { event in
                                    EventDetailView(event: event)
                                }
                        }

                    case .tickets:
                        NavigationStack(path: $appState.navigationCoordinator.ticketsPath) {
                            if useWalletView {
                                TicketsView(selectedTab: $appState.selectedTab)
                                    .navigationDestination(for: NavigationDestination.self) { destination in
                                        NavigationDestinationBuilder(destination: destination)
                                    }
                            } else {
                                TicketsWalletView(selectedTab: $appState.selectedTab)
                                    .navigationDestination(for: NavigationDestination.self) { destination in
                                        NavigationDestinationBuilder(destination: destination)
                                    }
                            }
                        }

                    case .settings:
                        NavigationStack(path: $appState.navigationCoordinator.settingsPath) {
                            SettingsView()
                                .navigationDestination(for: NavigationDestination.self) { destination in
                                    NavigationDestinationBuilder(destination: destination)
                                }
                        }
                    }
                }
                .ignoresSafeArea(.keyboard)

                // Conditionally show tab bar based on navigation state
                // Hide tab bar when there are items in the navigation path
                if !appState.navigationCoordinator.shouldHideTabBar && shouldShowTabBar {
                    VStack {
                        Spacer()
                        CustomTabBar()
                    }
                }
            }
        }
        .environmentObject(appState.navigationCoordinator)
    }
}

// Environment object to manage tab bar visibility
class TabBarVisibility: ObservableObject {
    @Binding var isDetailViewPresented: Bool

    init(isDetailViewPresented: Binding<Bool>) {
        self._isDetailViewPresented = isDetailViewPresented
    }

    func hideTabBar() {
        isDetailViewPresented = true
    }

    func showTabBar() {
        isDetailViewPresented = false
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
                if coordinator.selectedTab == .explore {
                    coordinator.focusSearchBar()
                } else {
                    coordinator.selectTab(.explore)
                }
            }

            Spacer()

            TabBarButton(
                icon: "ticket",
                isSelected: coordinator.selectedTab == .tickets
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
        .padding(.vertical, 16)
        .background(Color.black)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.appSectionHeader)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 20)

        }
        .buttonStyle(PlainButtonStyle())
    }
}
