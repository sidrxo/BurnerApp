import Foundation
import Supabase
import Combine
import UIKit

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepositoryProtocol
    private let supabase = SupabaseManager.shared.client
    private var authStateTask: Task<Void, Never>?
    
    // MARK: - Demo User Configuration
    // This email triggers the PIN entry flow instead of magic link
    let demoEmail = "demo@burner.com"  // Change this to your actual demo email
    private let demoPassword = "DemoSecurePassword2024!"  // Strong password for the demo account
    private let demoPIN = "001247"  // 6-digit PIN to unlock demo mode
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
        
        Task {
            await checkExistingSession()
        }
        
        setupAuthListener()
    }
    
    private func checkExistingSession() async {
        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                self.currentUser = session.user
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
            }
        }
    }
    
    private func setupAuthListener() {
        authStateTask?.cancel()

        authStateTask = Task {
            for await state in supabase.auth.authStateChanges {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.currentUser = state.session?.user
                }
            }
        }
    }
    
    // MARK: - Demo User Methods
    
    /// Check if an email is the demo email
    func isDemoEmail(_ email: String) -> Bool {
        return email.lowercased().trimmingCharacters(in: .whitespaces) == demoEmail.lowercased()
    }
    
    /// Validate the demo PIN
    func validateDemoPIN(_ pin: String) -> Bool {
        return pin == demoPIN
    }
    
    /// Sign in with demo account using PIN
    func signInWithDemoAccount() async throws {
        try await signInWithEmail(email: demoEmail, password: demoPassword)
    }
    
    // MARK: - User Profile Methods
    
    public func getUserProfile() async throws -> UserProfile? {
        guard let userId = currentUser?.id.uuidString else {
            return nil
        }
        return try await userRepository.fetchUserProfile(userId: userId)
    }
    
    func getUserCustomClaims() async throws -> [String: Any]? {
        guard let user = currentUser else {
            throw NSError(domain: "AuthenticationService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
        }
        return user.userMetadata
    }
    
    func getUserRole() async throws -> String? {
        let claims = try await getUserCustomClaims()
        if let role = claims?["role"] as? String {
            return role
        }
        
        let profile = try await getUserProfile()
        return profile?.role
    }
    
    func isScannerActive() async throws -> Bool {
        let claims = try await getUserCustomClaims()
        if let active = claims?["active"] as? Bool {
            return active
        }
        return false
    }
    
    func getVenueId() async throws -> String? {
        let claims = try await getUserCustomClaims()
        return claims?["venueId"] as? String
    }
    
    func hasRole(_ role: String) async throws -> Bool {
        let userRole = try await getUserRole()
        return userRole == role
    }
    
    func hasAnyRole(_ roles: [String]) async throws -> Bool {
        guard let userRole = try await getUserRole() else {
            return false
        }
        return roles.contains(userRole)
    }
    
    // MARK: - Authentication Methods
    
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            
            await MainActor.run {
                self.currentUser = session.user
            }
            
            let dateString = ISO8601DateFormatter().string(from: Date())
            try? await userRepository.updateUserProfile(
                userId: session.user.id.uuidString,
                data: ["lastLoginAt": dateString]
            )
            
            await MainActor.run {
                self.isLoading = false
            }
            
            // FIX: Remove immediate notification - let auth state listener handle it
            // This prevents multiple navigation updates when combined with view dismissals
            // NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            
            await MainActor.run {
                self.currentUser = session.user
            }
            
            let dateString = ISO8601DateFormatter().string(from: Date())
            try? await userRepository.updateUserProfile(
                userId: session.user.id.uuidString,
                data: ["lastLoginAt": dateString]
            )
            
            await MainActor.run {
                self.isLoading = false
            }
            
            try await Task.sleep(nanoseconds: 100_000_000)
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
            )
            
            await MainActor.run {
                self.currentUser = session.user
            }
            
            let dateString = ISO8601DateFormatter().string(from: Date())
            try? await userRepository.updateUserProfile(
                userId: session.user.id.uuidString,
                data: ["lastLoginAt": dateString]
            )
            
            await MainActor.run {
                self.isLoading = false
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(displayName)]
            )
            
            await MainActor.run {
                self.currentUser = session.user
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() throws {
        Task {
            do {
                try await supabase.auth.signOut()
                await MainActor.run {
                    self.currentUser = nil
                }
            } catch {
                print("Sign out error: \(error)")
            }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    deinit {
        authStateTask?.cancel()
    }
}
