import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Main app content
            MainTabView()
                .zIndex(0) // Ensure main content is behind onboarding

            // Onboarding overlay (shown when user is not authenticated)
            if appState.onboardingManager.shouldShowOnboarding {
                OnboardingFlowView()
                    .environmentObject(appState)
                    .environmentObject(appState.onboardingManager)
                    .environmentObject(appState.authService)
                    .transition(.opacity)
                    .zIndex(100) // Ensure onboarding is on top
                    .id("onboarding-\(appState.onboardingManager.shouldShowOnboarding)") // Force recreation when state changes
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.onboardingManager.shouldShowOnboarding)
        .onAppear {
            print("📱 [ContentView] Appeared - Show Onboarding: \(appState.onboardingManager.shouldShowOnboarding)")
            print("📱 [ContentView] Has Completed: \(appState.onboardingManager.hasCompletedOnboarding)")
            print("📱 [ContentView] Is Authenticated: \(appState.authService.currentUser != nil)")
        }
        .onChange(of: appState.onboardingManager.shouldShowOnboarding) { oldValue, newValue in
            print("📱 [ContentView] Onboarding state changed: \(oldValue) -> \(newValue)")
        }
        .onChange(of: appState.authService.currentUser) { oldValue, newValue in
            print("📱 [ContentView] Auth state changed: \(oldValue?.uid ?? "nil") -> \(newValue?.uid ?? "nil")")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
