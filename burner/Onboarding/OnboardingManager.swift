import Foundation
import Combine
import FirebaseAuth
import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var shouldShowOnboarding: Bool = false
    @Published var isFirstLaunch: Bool

    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "hasCompletedOnboarding"
    private let firstLaunchKey = "isFirstLaunch"
    private let hasEverSignedInKey = "hasEverSignedIn"
    
    // Hold a reference to the AuthenticationService
    private var authService: AuthenticationService?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers
    
    // Main Initializer: Use this for production/App startup
    init(authService: AuthenticationService) {
        self.authService = authService
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)

        // Check if this is the first launch (default is true, set to false after first launch)
        if !userDefaults.bool(forKey: firstLaunchKey) {
            // Very first launch ever
            self.isFirstLaunch = true
            userDefaults.set(true, forKey: firstLaunchKey)
        } else {
            self.isFirstLaunch = false
        }

        // Set initial state immediately based on current auth status
        let isAuthenticated = authService.currentUser != nil
        let hasEverSignedIn = userDefaults.bool(forKey: hasEverSignedInKey)

        // LOGIC:
        // - If signed IN -> Mark as having signed in, hide onboarding
        // - If signed OUT and NOT completed -> Show onboarding
        // - If signed OUT and COMPLETED -> Hide onboarding
        if isAuthenticated {
            // User is signed in - mark it and hide onboarding
            if !hasEverSignedIn {
                userDefaults.set(true, forKey: hasEverSignedInKey)
            }
            self.shouldShowOnboarding = false

            // Load preferences if they completed before
            if hasCompletedOnboarding {
                // Will load preferences after auth subscription is set up
            }
        } else {
            // Signed out - show onboarding if not completed
            self.shouldShowOnboarding = !hasCompletedOnboarding
        }

        // Setup the subscription to track auth state changes
        self.setupAuthSubscription()
    }

    // Secondary Initializer: For backward compatibility/Previews where Auth is unavailable
    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.shouldShowOnboarding = !hasCompletedOnboarding

        // Check if this is the first launch
        if !userDefaults.bool(forKey: firstLaunchKey) {
            self.isFirstLaunch = true
            userDefaults.set(true, forKey: firstLaunchKey)
        } else {
            self.isFirstLaunch = false
        }
    }

    // MARK: - Subscription Setup
    
    private func setupAuthSubscription() {
        // Observe sign-in/sign-out status
        authService?.$currentUser
            .dropFirst() // Skip the initial value since we handle it in init
            .sink { [weak self] user in
                self?.updateOnboardingStatus()
            }
            .store(in: &cancellables)
        
        // Also listen for explicit sign-in notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))
            .sink { [weak self] _ in
                // Mark that user has signed in
                self?.userDefaults.set(true, forKey: self?.hasEverSignedInKey ?? "hasEverSignedIn")
                // Small delay to ensure auth state is fully updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.updateOnboardingStatus()
                }
            }
            .store(in: &cancellables)
            
        // Listen for sign-out notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))
            .sink { [weak self] _ in
                self?.updateOnboardingStatus()
            }
            .store(in: &cancellables)
    }

    // MARK: - Status Update Logic
    
    private func updateOnboardingStatus() {
        let isAuthenticated = authService?.currentUser != nil
        let previousValue = shouldShowOnboarding

        // LOGIC:
        // - If signed IN and COMPLETED onboarding -> Hide onboarding (let them into app)
        // - If signed IN but NOT completed -> Keep showing onboarding (they need to finish the flow)
        // - If signed OUT and COMPLETED -> Hide onboarding (let them explore)
        // - If signed OUT and NOT completed -> Show onboarding

        if isAuthenticated {
            // User is signed in
            if hasCompletedOnboarding {
                // They've completed onboarding before, let them in
                self.shouldShowOnboarding = false
                loadUserPreferences()
            } else {
                // They signed in but haven't completed onboarding yet
                // Keep them in onboarding to set preferences
                self.shouldShowOnboarding = true
            }
        } else {
            // User is signed out - check if they've completed onboarding
            self.shouldShowOnboarding = !hasCompletedOnboarding
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

        // Mark first launch as complete
        isFirstLaunch = false

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
