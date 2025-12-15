import Foundation
import Supabase
import Combine
import UIKit

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepositoryProtocol // Updated to use protocol for better dependency management
    private let supabase = SupabaseManager.shared.client
    private var authStateTask: Task<Void, Never>?
    
    // NOTE: The UserRepository passed to init should conform to UserRepositoryProtocol.
    // Assuming UserRepository implements UserRepositoryProtocol.
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
            do {
                for await state in await supabase.auth.authStateChanges {
                    guard !Task.isCancelled else { return }
                    
                    await MainActor.run {
                        self.currentUser = state.session?.user
                    }
                }
            } catch {
                print("Auth state listener error: \(error)")
            }
        }
    }
    
    // MARK: - FIX: Make public so AppState can use it to fetch the full profile
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
        // Preference: check userMetadata first (fastest)
        let claims = try await getUserCustomClaims()
        if let role = claims?["role"] as? String {
            return role
        }
        
        // Fallback: fetch from profile table if metadata is missing
        let profile = try await getUserProfile()
        return profile?.role
    }
    
    func isScannerActive() async throws -> Bool {
        // Preference: check userMetadata first
        let claims = try await getUserCustomClaims()
        if let active = claims?["active"] as? Bool {
            return active
        }
        
        // Fallback: fetch from profile table
        // NOTE: This assumes 'isScannerActive' property exists on UserProfile
        return false // If the full profile is complex, assume false unless explicitly checked
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
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
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
            // FIX: Explicitly wrap the String in the .string() enum case for AnyJSON
            // The metadata here is often quickly accessible but might be different from the 'users' table
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
