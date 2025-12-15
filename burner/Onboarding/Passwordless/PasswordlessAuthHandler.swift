import SwiftUI
import Supabase
import Combine

/// Handler for processing passwordless authentication deep links
class PasswordlessAuthHandler: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?
    
    private let supabase = SupabaseManager.shared.client
    private let userRepository = UserRepository() // Assumes UserRepositoryProtocol conformance
    
    func handleSignInLink(url: URL) -> Bool {
        // Check if this URL contains the access_token parameter (Supabase magic link)
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems,
              queryItems.contains(where: { $0.name == "access_token" || $0.name == "token_type" }) else {
            return false
        }
        
        // Retrieve the email from storage
        guard let email = UserDefaults.standard.string(forKey: "pendingEmailForSignIn") else {
            self.error = "Email not found. Please try signing in again."
            return false
        }
        
        isProcessing = true
        
        Task {
            do {
                // Verify the OTP from the URL
                // Extract the token from URL
                let token = queryItems.first(where: { $0.name == "access_token" })?.value ?? ""
                let tokenType = queryItems.first(where: { $0.name == "token_type" })?.value ?? "magiclink"
                
                // Verify the OTP token
                let session = try await supabase.auth.verifyOTP(
                    email: email,
                    token: token,
                    type: .magiclink
                )
                
                await MainActor.run {
                    self.isProcessing = false
                }
                
                // Clear the stored email
                UserDefaults.standard.removeObject(forKey: "pendingEmailForSignIn")
                
                // Create or update user profile
                await createUserProfile(for: session.user)
                
                // Post notification for successful sign in
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
                }
                
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.error = "Sign in failed: \(error.localizedDescription)"
                }
            }
        }
        
        return true
    }
    
    /// Create or update user profile in Supabase
    private func createUserProfile(for user: User) async {
        do {
            // Check if user profile already exists
            let exists = try await userRepository.userExists(userId: user.id.uuidString)
            
            if !exists {
                // New user - create full profile
                let displayName = user.email?.components(separatedBy: "@").first ?? "User"
                
                // FIX: Now using the explicit memberwise initializer
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
}

// MARK: - App Integration Extension

extension PasswordlessAuthHandler {
    /// Call this from your App's onOpenURL modifier
    /// Example usage in your App struct:
    ///
    /// ```swift
    /// @StateObject private var passwordlessHandler = PasswordlessAuthHandler()
    ///
    /// var body: some Scene {
    ///     WindowGroup {
    ///         ContentView()
    ///             .onOpenURL { url in
    ///                 _ = passwordlessHandler.handleSignInLink(url: url)
    ///             }
    ///     }
    /// }
    /// ```
    static func configureDeepLinking(for app: some Scene) -> some Scene {
        return app
    }
}
