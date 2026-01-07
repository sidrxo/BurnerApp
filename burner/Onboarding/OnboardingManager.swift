import Foundation
import Combine
import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var shouldShowOnboarding: Bool = false

    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "hasCompletedOnboarding"
    
    private var cancellables = Set<AnyCancellable>()

    // Simplified init: Visibility depends ONLY on whether onboarding was completed locally.
    // Auth state no longer forces it to hide.
    init(authService: AuthenticationService) {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.shouldShowOnboarding = !hasCompletedOnboarding
    }

    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.shouldShowOnboarding = !hasCompletedOnboarding
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingCompletedKey)
        userDefaults.synchronize()
        
        shouldShowOnboarding = false
        objectWillChange.send()
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: onboardingCompletedKey)
        userDefaults.synchronize()
        
        shouldShowOnboarding = true
        objectWillChange.send()
    }
    
    func refreshState() {
        // Since we no longer depend on Auth, this simply ensures the published properties match UserDefaults
        let storedValue = userDefaults.bool(forKey: onboardingCompletedKey)
        if hasCompletedOnboarding != storedValue {
            hasCompletedOnboarding = storedValue
            shouldShowOnboarding = !storedValue
        }
    }
}
