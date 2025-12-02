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
            ZStack {
                // Home Tab
                NavigationStack(path: $coordinator.homePath) {
                    ExploreView()
                        .environment(\.heroNamespace, homeHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, homeHeroNamespace)
                        }
                }
                .opacity(coordinator.selectedTab == .home ? 1 : 0)
                .zIndex(coordinator.selectedTab == .home ? 1 : 0)

                // Explore Tab
                NavigationStack(path: $coordinator.explorePath) {
                    SearchView()
                        .environment(\.heroNamespace, exploreHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, exploreHeroNamespace)
                        }
                }
                .opacity(coordinator.selectedTab == .explore ? 1 : 0)
                .zIndex(coordinator.selectedTab == .explore ? 1 : 0)

                // Tickets Tab
                NavigationStack(path: $coordinator.ticketsPath) {
                    TicketsView()
                        .environment(\.heroNamespace, ticketsHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, ticketsHeroNamespace)
                        }
                }
                .opacity(coordinator.selectedTab == .tickets ? 1 : 0)
                .zIndex(coordinator.selectedTab == .tickets ? 1 : 0)

                // Settings Tab
                NavigationStack(path: $coordinator.settingsPath) {
                    SettingsView()
                        .environment(\.heroNamespace, settingsHeroNamespace)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                                .environment(\.heroNamespace, settingsHeroNamespace)
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
            // 1. Home
            TabBarButton(
                icon: "homeicon",
                isSelected: coordinator.selectedTab == .home
            ) {
                coordinator.selectTab(.home)
            }

            Spacer()

            // 2. Explore
            TabBarButton(
                icon: "searchicon",
                isSelected: coordinator.selectedTab == .explore
            ) {
                coordinator.selectTab(.explore)
            }

            Spacer()
            
            // 3. Bookmarks (Formerly Settings position, moved to 3rd slot)
            // Note: You need to add .bookmarks to your Tab enum in NavigationCoordinator
            TabBarButton(
                icon: "bookmarkicon",
                isSelected: coordinator.selectedTab == .settings
            ) {
                coordinator.selectTab(.settings)
            }

            Spacer()

            // 4. Tickets (Now the final tab, containing the nested settings)
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
            Image(icon)
                .renderingMode(.template) // Crucial: Allows .foregroundColor to work
                .resizable()              // Crucial: Allows SVG to resize
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isSelected ? .white : .gray)
                .rotationEffect(.degrees(rotationDegrees))
                .frame(width: 24, height: 24) // Visual size of the icon
                .frame(width: 44, height: 30) // Touch target size
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
