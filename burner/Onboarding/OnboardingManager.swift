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
    
    // Hold a reference to the AuthenticationService
    private var authService: AuthenticationService?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers
    
    // Main Initializer: Use this for production/App startup
    init(authService: AuthenticationService) {
        self.authService = authService
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)

        // Set initial state immediately based on current auth status
        let isAuthenticated = authService.currentUser != nil

        // NEW LOGIC: If no user is signed in, ALWAYS show onboarding first slide
        // regardless of whether they completed it before
        self.shouldShowOnboarding = !isAuthenticated

        print("🚀 [OnboardingManager] Initialized - Auth: \(isAuthenticated), Completed Before: \(hasCompletedOnboarding), Show: \(shouldShowOnboarding)")

        // Setup the subscription to track auth state changes
        self.setupAuthSubscription()
    }

    // Secondary Initializer: For backward compatibility/Previews where Auth is unavailable
    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingCompletedKey)
        self.shouldShowOnboarding = !hasCompletedOnboarding
        print("🚀 [OnboardingManager] Initialized (no auth) - Show: \(shouldShowOnboarding)")
    }

    // MARK: - Subscription Setup
    
    private func setupAuthSubscription() {
        // Observe sign-in/sign-out status
        authService?.$currentUser
            .dropFirst() // Skip the initial value since we handle it in init
            .sink { [weak self] user in
                print("👤 [OnboardingManager] Auth state changed - User: \(user?.uid ?? "nil")")
                self?.updateOnboardingStatus()
            }
            .store(in: &cancellables)
        
        // Also listen for explicit sign-in notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))
            .sink { [weak self] _ in
                print("✅ [OnboardingManager] Received UserSignedIn notification")
                // Small delay to ensure auth state is fully updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.updateOnboardingStatus()
                }
            }
            .store(in: &cancellables)
            
        // Listen for sign-out notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))
            .sink { [weak self] _ in
                print("🚪 [OnboardingManager] Received UserSignedOut notification")
                self?.updateOnboardingStatus()
            }
            .store(in: &cancellables)
    }

    // MARK: - Status Update Logic
    
    private func updateOnboardingStatus() {
        let isAuthenticated = authService?.currentUser != nil
        let previousValue = shouldShowOnboarding

        // NEW LOGIC:
        // - If signed IN -> Always hide onboarding (let them into app)
        // - If signed OUT -> Always show onboarding first slide (even if completed before)

        if isAuthenticated {
            // User is signed in, always dismiss onboarding
            // Load their preferences from Firestore
            self.shouldShowOnboarding = false
            loadUserPreferences()
        } else {
            // User is signed out - always show onboarding first slide
            self.shouldShowOnboarding = true
        }

        // Force UI update if value changed
        if previousValue != shouldShowOnboarding {
            print("🔄 [OnboardingManager] State changed: \(previousValue) -> \(shouldShowOnboarding)")
            // Force explicit UI update
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }

        print("👤 [OnboardingManager] Auth: \(isAuthenticated ? "✅ Signed In" : "❌ Signed Out") | Completed Before: \(hasCompletedOnboarding ? "✅ Yes" : "❌ No") -> Show Onboarding: \(shouldShowOnboarding ? "✅ YES" : "❌ NO")")
    }

    // Load user preferences from Firestore when signed in
    private func loadUserPreferences() {
        Task {
            let syncService = PreferencesSyncService()
            if let firebasePrefs = await syncService.loadPreferencesFromFirebase() {
                print("✅ [OnboardingManager] Loaded preferences from Firestore")
                // Apply preferences to local storage
                firebasePrefs.saveToUserDefaults()
            }
        }
    }

    // MARK: - Public Methods
    
    func completeOnboarding() {
        print("🎯 [OnboardingManager] completeOnboarding() called")
        
        // Save completion state
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingCompletedKey)
        userDefaults.synchronize() // Force immediate save
        print("✅ [OnboardingManager] Onboarding marked as completed and saved")
        
        // Always dismiss when completing onboarding (whether authenticated or not)
        print("✅ [OnboardingManager] Dismissing onboarding after completion...")
        
        // Use explicit main actor and multiple update strategies to ensure UI updates
        Task { @MainActor in
            // First, send objectWillChange to notify SwiftUI
            self.objectWillChange.send()
            
            // Then update the state
            withAnimation(.easeOut(duration: 0.3)) {
                self.shouldShowOnboarding = false
            }
            
            // Additional explicit notification after animation starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.objectWillChange.send()
            }
            
            print("✅ [OnboardingManager] shouldShowOnboarding set to: \(self.shouldShowOnboarding)")
        }
    }

    // Reset onboarding (useful for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: onboardingCompletedKey)
        userDefaults.synchronize()
        updateOnboardingStatus()
        print("🔄 [OnboardingManager] Onboarding reset")
    }
    
    // Manual refresh method for debugging
    func refreshState() {
        print("🔄 [OnboardingManager] Manual refresh requested")
        updateOnboardingStatus()
    }
}
