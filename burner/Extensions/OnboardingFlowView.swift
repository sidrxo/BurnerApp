import SwiftUI
import FirebaseAuth

struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var burnerManager: BurnerModeManager
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var currentStep: OnboardingStep = .signIn
    @State private var showingSignIn = true
    @State private var showingBurnerSetup = false
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
                SignInSheetView(showingSignIn: $showingSignIn)
                    .transition(.opacity)
            }
            
            // Burner Setup Step
            if currentStep == .burnerSetup {
                if showingBurnerSetup {
                    BurnerModeSetupView(burnerManager: burnerManager)
                        .interactiveDismissDisabled()
                        .onDisappear {
                            completeBurnerSetup()
                        }
                        .transition(.move(edge: .trailing))
                } else {
                    BurnerSetupPromptView(
                        onSetup: {
                            withAnimation {
                                showingBurnerSetup = true
                            }
                        },
                        onSkip: {
                            skipBurnerSetup()
                        }
                    )
                    .transition(.opacity)
                }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            handleUserSignIn()
        }
    }
    
    private func handleUserSignIn() {
        onboardingManager.completeSignIn()
        moveToNextStep()
    }
    
    private func checkSignInStatus() {
        // Delay to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authService.currentUser != nil {
                handleUserSignIn()
            } else {
                // User skipped sign in - complete onboarding
                onboardingManager.completeOnboarding()
            }
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
    
    private func completeBurnerSetup() {
        onboardingManager.completeBurnerSetup()
        onboardingManager.completeOnboarding()
    }
    
    private func skipBurnerSetup() {
        onboardingManager.skipBurnerSetup()
    }
}

// MARK: - Burner Setup Prompt View
struct BurnerSetupPromptView: View {
    let onSetup: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                Image(systemName: "flame.fill")
                    .font(.appLargeIcon)
                    .foregroundColor(.orange)
                    .padding(.bottom, 32)
                
                // Title and description
                VStack(spacing: 16) {
                    Text("Stay Focused at Events")
                        .appPageHeader()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Set up Burner Mode to block distracting apps during events and stay present in the moment.")
                        .appBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 48)
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "Block Distractions",
                        description: "Restrict access to apps during events"
                    )
                    
                    FeatureRow(
                        icon: "clock.fill",
                        title: "Automatic Activation",
                        description: "Activates during your ticket events"
                    )
                    
                    FeatureRow(
                        icon: "hand.raised.fill",
                        title: "Privacy Protected",
                        description: "No data collection or tracking"
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: onSetup) {
                        Text("Set Up Burner Mode")
                            .appBody()
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: onSkip) {
                        Text("Skip for Now")
                            .appBody()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingFlowView(
        onboardingManager: OnboardingManager(),
        burnerManager: BurnerModeManager()
    )
    .environmentObject(AppState().authService)
}
