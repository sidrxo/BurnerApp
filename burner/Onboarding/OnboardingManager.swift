import Foundation
import Combine
import FirebaseAuth
import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var shouldShowOnboarding: Bool = false
    @Published var hasEverSignedIn: Bool
    @Published var appLaunchCount: Int

    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "hasCompletedOnboarding"
    private let hasEverSignedInKey = "hasEverSignedIn"
    private let appLaunchCountKey = "appLaunchCount"

    // Hold a reference to the AuthenticationService
    private var authService: AuthenticationService?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers
    
    // Main Initializer: Use this for production/App startup
    init(authService: AuthenticationService) {
        self.authService = authService
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.hasEverSignedIn = userDefaults.bool(forKey: hasEverSignedInKey)
        self.appLaunchCount = userDefaults.integer(forKey: appLaunchCountKey)

        // Increment launch count on each app start
        self.appLaunchCount += 1
        userDefaults.set(self.appLaunchCount, forKey: appLaunchCountKey)

        // Set initial state immediately based on current auth status
        let isAuthenticated = authService.currentUser != nil

        // LOGIC:
        // - If signed IN -> Never show onboarding
        // - If signed OUT and COMPLETED -> Hide onboarding
        // - If signed OUT, NOT completed, and within first 2 launches -> Show onboarding
        // - If signed OUT, NOT completed, but past 2 launches -> Hide onboarding (too late)
        if isAuthenticated {
            // Mark that user has signed in
            if !hasEverSignedIn {
                hasEverSignedIn = true
                userDefaults.set(true, forKey: hasEverSignedInKey)
            }

            // Signed in - never show onboarding
            self.shouldShowOnboarding = false

            // If they completed before, load their preferences
            if hasCompletedOnboarding {
                // Will load preferences after auth subscription is set up
            }
        } else {
            // Signed out - only show onboarding if not completed AND within first 2 launches
            self.shouldShowOnboarding = !hasCompletedOnboarding && appLaunchCount <= 2
        }

        // Setup the subscription to track auth state changes
        self.setupAuthSubscription()
    }

    // Secondary Initializer: For backward compatibility/Previews where Auth is unavailable
    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.hasEverSignedIn = userDefaults.bool(forKey: hasEverSignedInKey)
        self.appLaunchCount = userDefaults.integer(forKey: appLaunchCountKey)
        self.shouldShowOnboarding = !hasCompletedOnboarding && appLaunchCount <= 2

    }

    // MARK: - Subscription Setup

    private func setupAuthSubscription() {
        // Observe sign-in/sign-out status
        // The authService.$currentUser publisher already handles all auth state changes,
        // so we don't need redundant notification listeners that cause UI flashing
        authService?.$currentUser
            .dropFirst() // Skip the initial value since we handle it in init
            .sink { [weak self] user in
                self?.updateOnboardingStatus()
            }
            .store(in: &cancellables)
    }

    // MARK: - Status Update Logic
    
    private func updateOnboardingStatus() {
        let isAuthenticated = authService?.currentUser != nil
        let previousValue = shouldShowOnboarding

        // LOGIC:
        // - If signed IN -> Never show onboarding (let them into app)
        // - If signed OUT and COMPLETED -> Hide onboarding (let them explore)
        // - If signed OUT, NOT completed, and within first 2 launches -> Show onboarding
        // - If signed OUT, NOT completed, but past 2 launches -> Hide onboarding

        if isAuthenticated {
            // Mark that user has signed in
            if !hasEverSignedIn {
                hasEverSignedIn = true
                userDefaults.set(true, forKey: hasEverSignedInKey)
            }

            // User is signed in - never show onboarding on sign-in (prevents flash)
            // Use a slight delay to ensure smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.shouldShowOnboarding = false
                if self.hasCompletedOnboarding {
                    self.loadUserPreferences()
                }
            }
        } else {
            // User is signed out - only show onboarding if not completed AND within first 2 launches
            self.shouldShowOnboarding = !hasCompletedOnboarding && appLaunchCount <= 2
        }

        // Force UI update if value changed
        if previousValue != shouldShowOnboarding {
            // Force explicit UI update
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }

    // Load user preferences from Firestore when signed in
    private func loadUserPreferences() {
        Task {
            let syncService = PreferencesSyncService()
            if let firebasePrefs = await syncService.loadPreferencesFromFirebase() {
                // Apply preferences to local storage
                firebasePrefs.saveToUserDefaults()
            }
        }
    }

    // MARK: - Public Methods
    
    func completeOnboarding() {
        // Save completion state
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingCompletedKey)
        userDefaults.synchronize() // Force immediate save
        
        // Force SwiftUI to notice the change by explicitly calling objectWillChange
        objectWillChange.send()
        
        // Simple, direct state update
        shouldShowOnboarding = false
    }

    // Reset onboarding (useful for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: onboardingCompletedKey)
        userDefaults.synchronize()
        updateOnboardingStatus()
    }
    
    // Manual refresh method for debugging
    func refreshState() {
        updateOnboardingStatus()
    }
}
