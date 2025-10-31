import SwiftUI
import FirebaseAuth
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                switch appState.selectedTab {
                case 0:
                    HomeView()
                case 1:
                    ExploreView()
                case 2:
                    TicketsView(selectedTab: $appState.selectedTab)
                case 3:
                    SettingsView()
                default:
                    HomeView()
                }
            }

            // Custom Tab Bar - only show when detail view is not presented
            if !appState.isDetailViewPresented {
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $appState.selectedTab)
                }
            }
        }
        .ignoresSafeArea(.keyboard)

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
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarButton(
                icon: "house",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            Spacer()
            
            TabBarButton(
                icon: "magnifyingglass",
                isSelected: selectedTab == 1
            ) {
                if selectedTab == 1 {
                    // Already on search tab - notify to focus search
                    NotificationCenter.default.post(name: NSNotification.Name("FocusSearchBar"), object: nil)
                } else {
                    // Navigate to search tab
                    selectedTab = 1
                }
            }
            
            Spacer()
            
            TabBarButton(
                icon: "ticket",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            Spacer()
            
            TabBarButton(
                icon: "person",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
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
