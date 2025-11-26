import SwiftUI
import FirebaseAuth

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
        .onAppear {
            print("📱 [ContentView] Appeared - Show Onboarding: \(onboardingManager.shouldShowOnboarding)")
            print("📱 [ContentView] Has Completed: \(onboardingManager.hasCompletedOnboarding)")
            print("📱 [ContentView] Is Authenticated: \(appState.authService.currentUser != nil)")
        }
        .onChange(of: onboardingManager.shouldShowOnboarding) { oldValue, newValue in
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
