import Foundation
import Combine
import FirebaseAuth

@MainActor
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var hasCompletedSignIn: Bool
    @Published var hasCompletedBurnerSetup: Bool
    @Published var shouldShowOnboarding: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "hasCompletedOnboarding"
    private let signInCompletedKey = "hasCompletedSignIn"
    private let burnerSetupCompletedKey = "hasCompletedBurnerSetup"
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.hasCompletedSignIn = userDefaults.bool(forKey: signInCompletedKey)
        self.hasCompletedBurnerSetup = userDefaults.bool(forKey: burnerSetupCompletedKey)
        
        // Show onboarding if it hasn't been completed
        self.shouldShowOnboarding = !hasCompletedOnboarding
        
        setupAuthListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                if user != nil && !self.hasCompletedSignIn {
                    self.completeSignIn()
                }
            }
        }
    }
    
    func completeSignIn() {
        hasCompletedSignIn = true
        userDefaults.set(true, forKey: signInCompletedKey)
    }
    
    func completeBurnerSetup() {
        hasCompletedBurnerSetup = true
        userDefaults.set(true, forKey: burnerSetupCompletedKey)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        shouldShowOnboarding = false
        userDefaults.set(true, forKey: onboardingCompletedKey)
    }
    
    func skipBurnerSetup() {
        hasCompletedBurnerSetup = true
        userDefaults.set(true, forKey: burnerSetupCompletedKey)
        completeOnboarding()
    }
    
    // Reset onboarding (useful for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasCompletedSignIn = false
        hasCompletedBurnerSetup = false
        shouldShowOnboarding = true
        
        userDefaults.set(false, forKey: onboardingCompletedKey)
        userDefaults.set(false, forKey: signInCompletedKey)
        userDefaults.set(false, forKey: burnerSetupCompletedKey)
    }
}
