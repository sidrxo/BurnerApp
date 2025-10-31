import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingManager = OnboardingManager()
    @StateObject private var burnerManager = BurnerModeManager()

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            ZStack {
                // Main app content (ensure MainTabView switches tabs using appState.selectedTab)
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

            // Deep-link destination: push EventDetail when we append an eventId (String)
            .navigationDestination(for: String.self) { eventId in
                EventDetailDestination(eventId: eventId)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
