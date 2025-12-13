import Foundation
import Combine
import FirebaseAuth
import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var shouldShowOnboarding: Bool = false

    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "hasCompletedOnboarding"
    
    private var authService: AuthenticationService?
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthenticationService) {
        self.authService = authService
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)

        let isAuthenticated = authService.currentUser != nil

        // MODIFIED LOGIC: If authenticated, never show onboarding.
        if isAuthenticated {
            self.shouldShowOnboarding = false
            Task {
                await self.loadUserPreferences()
            }
        } else {
            // If signed out, show onboarding only if they haven't completed it before.
            self.shouldShowOnboarding = !hasCompletedOnboarding
        }

        self.setupAuthSubscription()
    }

    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.shouldShowOnboarding = !hasCompletedOnboarding
    }

    private func setupAuthSubscription() {
        authService?.$currentUser
            .dropFirst()
            .sink { [weak self] user in
                self?.updateOnboardingStatus()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.updateOnboardingStatus()
                }
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))
            .sink { [weak self] _ in
                self?.updateOnboardingStatus()
            }
            .store(in: &cancellables)
    }

    private func updateOnboardingStatus() {
        let isAuthenticated = authService?.currentUser != nil
        let previousValue = shouldShowOnboarding

        // MODIFIED LOGIC: If authenticated, never show onboarding.
        if isAuthenticated {
            self.shouldShowOnboarding = false
            Task {
                await loadUserPreferences()
            }
        } else {
            // If signed out, show onboarding only if they haven't completed it.
            self.shouldShowOnboarding = !hasCompletedOnboarding
        }

        if previousValue != shouldShowOnboarding {
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }

    private func loadUserPreferences() async {
        let syncService = PreferencesSyncService()
        if let firebasePrefs = await syncService.loadPreferencesFromFirebase() {
            firebasePrefs.saveToUserDefaults()
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingCompletedKey)
        userDefaults.synchronize()
        
        objectWillChange.send()
        
        shouldShowOnboarding = false
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: onboardingCompletedKey)
        userDefaults.synchronize()
        updateOnboardingStatus()
    }
    
    func refreshState() {
        updateOnboardingStatus()
    }
}
