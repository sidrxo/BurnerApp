import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingManager = OnboardingManager()
    @StateObject private var burnerManager = BurnerModeManager()
    
    var body: some View {
        ZStack {
            // Main app content
            MainTabView()
            
            // Onboarding overlay (shown on first launch)
            if onboardingManager.shouldShowOnboarding {
                OnboardingFlowView(
                    onboardingManager: onboardingManager,
                    burnerManager: burnerManager
                )
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
