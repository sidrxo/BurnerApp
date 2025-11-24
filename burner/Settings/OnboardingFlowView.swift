import SwiftUI
import FirebaseAuth

struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var burnerManager: BurnerModeManager
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var currentStep: OnboardingStep = .signIn
    @State private var showingSignIn = true
    @Environment(\.dismiss) private var dismiss
    
    enum OnboardingStep {
        case signIn
        case burnerSetup
        case complete
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Sign In Step
            if currentStep == .signIn {
                SignInSheetView(
                    showingSignIn: $showingSignIn,
                    onSkip: {
                        skipOnboarding()
                    }
                )
                .transition(.opacity)
            }
            
            // Burner Setup Step - goes directly to setup
            if currentStep == .burnerSetup {
                BurnerModeSetupView(
                    burnerManager: burnerManager,
                    onSkip: {
                        skipBurnerSetup()
                    }
                )
                .transition(.move(edge: .trailing))
            }
        }
        .onChange(of: showingSignIn) { oldValue, newValue in
            if !newValue && currentStep == .signIn {
                checkSignInStatus()
            }
        }
        .onChange(of: authService.currentUser) { oldValue, newValue in
            if newValue != nil && !onboardingManager.hasCompletedSignIn {
                handleUserSignIn()
            }
        }
    }
    
    private func handleUserSignIn() {
        onboardingManager.completeSignIn()
        moveToNextStep()
    }
    
    private func checkSignInStatus() {
        if authService.currentUser != nil {
            handleUserSignIn()
        } else {
            // User closed sign in - skip entire onboarding
            skipOnboarding()
        }
    }
    
    private func moveToNextStep() {
        withAnimation(.easeInOut(duration: 0.5)) {
            if !onboardingManager.hasCompletedBurnerSetup {
                currentStep = .burnerSetup
            } else {
                currentStep = .complete
                onboardingManager.completeOnboarding()
            }
        }
    }
    
    private func skipBurnerSetup() {
        onboardingManager.skipBurnerSetup()
    }
    
    private func skipOnboarding() {
        onboardingManager.completeOnboarding()
    }
}

#Preview {
    OnboardingFlowView(
        onboardingManager: OnboardingManager(),
        burnerManager: BurnerModeManager()
    )
    .environmentObject(AppState().authService)
}
