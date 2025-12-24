import SwiftUI
import Supabase
import Combine

/// Handler for processing passwordless authentication deep links
class PasswordlessAuthHandler: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?
    
    private let supabase = SupabaseManager.shared.client
    private let userRepository = UserRepository()
    
    // Optional coordinator for showing user-friendly alerts
    var coordinator: NavigationCoordinator?
    
    func handleSignInLink(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        
        let isValidScheme = url.scheme == "burner" ||
                           (url.scheme == "https" && url.host == "burnerlive.com")
        
        guard isValidScheme else { return false }
        
        // 1. Check for Fragment (Redirect Flow - most common for Magic Links)
        // URL looks like: burner://signin#access_token=...&refresh_token=...
        if let fragment = components.fragment, fragment.contains("access_token") {
            isProcessing = true
            handleSessionFromURL(url)
            return true
        }
        
        // 2. Check for Query Items (Manual OTP Token Flow)
        // URL looks like: burner://signin?token=...&type=magiclink
        if let queryItems = components.queryItems,
           let token = queryItems.first(where: { $0.name == "token" || $0.name == "token_hash" })?.value {
            
            // For manual verification, we need the email we stored earlier
            guard let email = UserDefaults.standard.string(forKey: "pendingEmailForSignIn") else {
                self.error = "Email not found. Please try signing in again."
                showUserError(title: "Sign In Error", message: "Session expired. Please request a new sign-in link.")
                return false
            }
            
            isProcessing = true
            handleManualVerification(email: email, token: token)
            return true
        }
        
        return false
    }
    
    /// Handles the implicit/redirect flow where Supabase provides the session directly in the URL
    private func handleSessionFromURL(_ url: URL) {
        Task {
            do {
                // This parses the URL fragment and sets the session automatically
                let session = try await supabase.auth.session(from: url)
                await finalizeSignIn(session: session)
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.error = "Failed to parse session: \(error.localizedDescription)"
                    
                    // Show user-friendly error based on error type
                    self.handleAuthError(error)
                }
            }
        }
    }
    
    /// Handles the manual flow where we exchange a token/code for a session
    private func handleManualVerification(email: String, token: String) {
        Task {
            do {
                // FIX: verifyOTP returns AuthResponse, so we must extract the session
                let response = try await supabase.auth.verifyOTP(
                    email: email,
                    token: token,
                    type: .magiclink
                )
                
                // Safely unwrap the session
                guard let session = response.session else {
                    await MainActor.run {
                        self.isProcessing = false
                        self.error = "Sign in failed: No session returned."
                        self.showUserError(title: "Sign In Failed", message: "Unable to complete sign in. Please try again.")
                    }
                    return
                }
                
                await finalizeSignIn(session: session)
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.error = "Sign in failed: \(error.localizedDescription)"
                    
                    // Show user-friendly error
                    self.handleAuthError(error)
                }
            }
        }
    }
    
    /// Shared logic to run after a successful sign-in
    private func finalizeSignIn(session: Session) async {
        await MainActor.run {
            self.isProcessing = false
        }
        
        // Clear the stored email as it's no longer needed
        UserDefaults.standard.removeObject(forKey: "pendingEmailForSignIn")
        
        // Create or update user profile
        await createUserProfile(for: session.user)
        
        // Post notification to dismiss the view
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
        }
    }
    
    /// Create or update user profile in Supabase
    private func createUserProfile(for user: User) async {
        do {
            // Check if user profile already exists
            let exists = try await userRepository.userExists(userId: user.id.uuidString)
            
            if !exists {
                // New user - create full profile
                let displayName = user.email?.components(separatedBy: "@").first ?? "User"
                
                let profile = UserProfile(
                    id: user.id.uuidString,
                    email: user.email ?? "",
                    displayName: displayName,
                    role: "user",
                    provider: "emailLink",
                    venuePermissions: [],
                    createdAt: Date(),
                    lastLoginAt: Date(),
                    phoneNumber: nil,
                    stripeCustomerId: nil,
                    profileImageUrl: nil,
                    preferences: nil
                )
                
                try await userRepository.createUserProfile(userId: user.id.uuidString, profile: profile)
            } else {
                // Existing user - just update last login
                try await userRepository.updateUserProfile(
                    userId: user.id.uuidString,
                    data: ["lastLoginAt": Date()]
                )
            }
        } catch {
            print("Failed to create/update user profile: \(error.localizedDescription)")
        }
    }
    
    /// Handle authentication errors with user-friendly messages
    private func handleAuthError(_ error: Error) {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("expired") || errorString.contains("otp_expired") {
            showUserError(
                title: "Link Expired",
                message: "This sign-in link has expired. Please request a new one."
            )
        } else if errorString.contains("invalid") || errorString.contains("access_denied") {
            showUserError(
                title: "Invalid Link",
                message: "This sign-in link is invalid or has already been used. Please request a new one."
            )
        } else if errorString.contains("network") || errorString.contains("connection") {
            showUserError(
                title: "Connection Error",
                message: "Unable to connect. Please check your internet connection and try again."
            )
        } else {
            showUserError(
                title: "Sign In Failed",
                message: "Something went wrong. Please try requesting a new sign-in link."
            )
        }
    }
    
    /// Show user-friendly error alert
    private func showUserError(title: String, message: String) {
        // Show CustomAlertView through coordinator
        if let coordinator = coordinator {
            coordinator.showCustomAlert(title: title, message: message)
        }
        
        // Also trigger haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}

// MARK: - App Integration Extension

extension PasswordlessAuthHandler {
    static func configureDeepLinking(for app: some Scene) -> some Scene {
        return app
    }
}
