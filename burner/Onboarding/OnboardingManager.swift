import SwiftUI
import Combine
import Shared // ✅ Import KMP

@MainActor
class OnboardingManager: ObservableObject {
    @Published var shouldShowOnboarding: Bool = false
    @Published var currentStep: Int = 0
    
    // ✅ Change type to Shared.AuthService
    private let authService: Shared.AuthService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: Shared.AuthService) {
        self.authService = authService
        checkOnboardingStatus()
    }
    
    func checkOnboardingStatus() {
        // Simple check: If user ID exists, they are logged in/onboarded
        // You can expand this logic based on your needs
        if authService.getCurrentUserId() != nil {
            shouldShowOnboarding = false
        } else {
            shouldShowOnboarding = true
        }
    }
    
    func completeOnboarding() {
        withAnimation {
            shouldShowOnboarding = false
        }
    }
}
