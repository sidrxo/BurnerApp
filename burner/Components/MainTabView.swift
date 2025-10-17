import SwiftUI
import FirebaseAuth
import Combine

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isDetailViewPresented = false
    
    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                        .environmentObject(TabBarVisibility(isDetailViewPresented: $isDetailViewPresented))
                case 1:
                    ExploreView()
                        .environmentObject(TabBarVisibility(isDetailViewPresented: $isDetailViewPresented))
                case 2:
                    TicketsView(selectedTab: $selectedTab)
                        .environmentObject(TabBarVisibility(isDetailViewPresented: $isDetailViewPresented))
                case 3:
                    SettingsView()
                        .environmentObject(TabBarVisibility(isDetailViewPresented: $isDetailViewPresented))
                default:
                    HomeView()
                        .environmentObject(TabBarVisibility(isDetailViewPresented: $isDetailViewPresented))
                }
            }
            
            // Custom Tab Bar - only show when detail view is not presented
            if !isDetailViewPresented {
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
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
                selectedTab = 1
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
