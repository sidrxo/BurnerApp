import SwiftUI
import Shared

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    var body: some View {
        ZStack {
            // Main app content
            MainTabView()
                .zIndex(0)

            // Onboarding overlay
            if onboardingManager.shouldShowOnboarding {
                OnboardingFlowView()
                    .environmentObject(appState)
                    .environmentObject(onboardingManager)
                    // We pass authService via init parameter if needed, NOT environmentObject
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.shouldShowOnboarding)
    }
}
