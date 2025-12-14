import Foundation
import Supabase
import Combine
import UIKit

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepository
    private let supabase = SupabaseManager.shared.client
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Task {
            for await state in await supabase.auth.authStateChanges {
                await MainActor.run {
                    self.currentUser = state.session?.user
                }
            }
        }
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
        return claims?["role"] as? String
    }
    
    func isScannerActive() async throws -> Bool {
        let claims = try await getUserCustomClaims()
        return claims?["active"] as? Bool ?? false
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
            currentUser = session.user
            
            try await userRepository.updateUserProfile(
                userId: session.user.id.uuidString,
                data: ["lastLoginAt": Date()]
            )
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
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
            
            currentUser = session.user
            
            let isNewUser = session.user.createdAt == session.user.updatedAt
            
            if isNewUser {
                var displayName = "Apple User"
                if let fullName = fullName {
                    let firstName = fullName.givenName ?? ""
                    let lastName = fullName.familyName ?? ""
                    displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                    if displayName.isEmpty {
                        displayName = "Apple User"
                    }
                }
                
                let profile = UserProfile(
                    email: session.user.email ?? "",
                    displayName: displayName,
                    role: "user",
                    provider: "apple",
                    venuePermissions: [],
                    createdAt: Date(),
                    lastLoginAt: Date()
                )
                
                try await userRepository.createUserProfile(userId: session.user.id.uuidString, profile: profile)
            } else {
                try await userRepository.updateUserProfile(
                    userId: session.user.id.uuidString,
                    data: ["lastLoginAt": Date()]
                )
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
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
            
            currentUser = session.user
            
            let isNewUser = session.user.createdAt == session.user.updatedAt
            
            if isNewUser {
                let profile = UserProfile(
                    email: session.user.email ?? "",
                    displayName: session.user.userMetadata["full_name"] as? String ?? "Google User",
                    role: "user",
                    provider: "google",
                    venuePermissions: [],
                    createdAt: Date(),
                    lastLoginAt: Date()
                )
                
                try await userRepository.createUserProfile(userId: session.user.id.uuidString, profile: profile)
            } else {
                try await userRepository.updateUserProfile(
                    userId: session.user.id.uuidString,
                    data: ["lastLoginAt": Date()]
                )
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signUp(email: email, password: password)
            currentUser = session.user
            
            let profile = UserProfile(
                email: email,
                displayName: displayName,
                role: "user",
                provider: "email",
                venuePermissions: [],
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            try await userRepository.createUserProfile(userId: session.user.id.uuidString, profile: profile)
            
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() throws {
        Task {
            try await supabase.auth.signOut()
            await MainActor.run {
                currentUser = nil
            }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
