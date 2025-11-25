import Foundation
import Combine

@MainActor
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var shouldShowOnboarding: Bool = false

    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "hasCompletedOnboarding"

    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)

        // Show onboarding if it hasn't been completed
        self.shouldShowOnboarding = !hasCompletedOnboarding
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        shouldShowOnboarding = false
        userDefaults.set(true, forKey: onboardingCompletedKey)
        print("✅ Onboarding completed")
    }

    // Reset onboarding (useful for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        shouldShowOnboarding = true
        userDefaults.set(false, forKey: onboardingCompletedKey)
        print("🔄 Onboarding reset")
    }
}
