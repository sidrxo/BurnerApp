import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    var body: some View {
        ZStack {
            // Main app content
            MainTabView()
                .zIndex(0) // Ensure main content is behind onboarding

            // Onboarding overlay (shown when user is not authenticated)
            if onboardingManager.shouldShowOnboarding {
                OnboardingFlowView()
                    .environmentObject(appState)
                    .environmentObject(onboardingManager)
                    .environmentObject(appState.authService)
                    .transition(.opacity)
                    .zIndex(100) // Ensure onboarding is on top
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.shouldShowOnboarding)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
