import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingManager = OnboardingManager()

    var body: some View {
        ZStack {
            // Main app content
            MainTabView()

            // Onboarding overlay (shown on first launch)
            if onboardingManager.shouldShowOnboarding {
                OnboardingFlowView(
                    onboardingManager: onboardingManager
                )
                .environmentObject(appState)
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingManager.shouldShowOnboarding)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
