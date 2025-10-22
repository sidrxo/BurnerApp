//
//  AuthenticationService.swift
//  burner
//
//  Created by Sid Rao on 22/10/2025.
//


import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepository
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        self.currentUser = Auth.auth().currentUser
        setupAuthStateListener()
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }
    
    // MARK: - Custom Claims Methods
    
    /// Get all custom claims for the current user
    func getUserCustomClaims() async throws -> [String: Any]? {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthenticationService", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
        }
        
        // Force token refresh to get latest custom claims
        let result = try await user.getIDTokenResult(forcingRefresh: true)
        return result.claims
    }
    
    /// Get the user's role from custom claims
    func getUserRole() async throws -> String? {
        let claims = try await getUserCustomClaims()
        return claims?["role"] as? String
    }
    
    /// Check if scanner is active from custom claims
    func isScannerActive() async throws -> Bool {
        let claims = try await getUserCustomClaims()
        return claims?["active"] as? Bool ?? false
    }
    
    /// Get venue ID from custom claims
    func getVenueId() async throws -> String? {
        let claims = try await getUserCustomClaims()
        return claims?["venueId"] as? String
    }
    
    /// Check if user has a specific role
    func hasRole(_ role: String) async throws -> Bool {
        let userRole = try await getUserRole()
        return userRole == role
    }
    
    /// Check if user has any of the specified roles
    func hasAnyRole(_ roles: [String]) async throws -> Bool {
        guard let userRole = try await getUserRole() else {
            return false
        }
        return roles.contains(userRole)
    }
    
    // MARK: - Sign In Methods
    
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            
            // Update last login time in Firestore
            try await userRepository.updateUserProfile(
                userId: result.user.uid,
                data: ["lastLoginAt": Date()]
            )
            
            // Post notification for successful sign in
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
            let credential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: idToken,
                rawNonce: nonce
            )
            
            let result = try await Auth.auth().signIn(with: credential)
            currentUser = result.user
            
            // Check if this is a new user
            if result.additionalUserInfo?.isNewUser == true {
                // Create user profile in Firestore
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
                    email: result.user.email ?? "",
                    displayName: displayName,
                    role: "user",
                    provider: "apple",
                    venuePermissions: [],
                    createdAt: Date(),
                    lastLoginAt: Date()
                )
                
                try await userRepository.createUserProfile(userId: result.user.uid, profile: profile)
            } else {
                // Update last login time
                try await userRepository.updateUserProfile(
                    userId: result.user.uid,
                    data: ["lastLoginAt": Date()]
                )
            }
            
            // Post notification for successful sign in
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
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            
            let result = try await Auth.auth().signIn(with: credential)
            currentUser = result.user
            
            // Check if this is a new user
            if result.additionalUserInfo?.isNewUser == true {
                let profile = UserProfile(
                    email: result.user.email ?? "",
                    displayName: result.user.displayName ?? "Google User",
                    role: "user",
                    provider: "google",
                    venuePermissions: [],
                    createdAt: Date(),
                    lastLoginAt: Date()
                )
                
                try await userRepository.createUserProfile(userId: result.user.uid, profile: profile)
            } else {
                // Update last login time
                try await userRepository.updateUserProfile(
                    userId: result.user.uid,
                    data: ["lastLoginAt": Date()]
                )
            }
            
            // Post notification for successful sign in
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Up
    
    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = result.user
            
            // Create user profile in Firestore
            let profile = UserProfile(
                email: email,
                displayName: displayName,
                role: "user",
                provider: "email",
                venuePermissions: [],
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            try await userRepository.createUserProfile(userId: result.user.uid, profile: profile)
            
            // Post notification for successful sign in
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        
        // Post notification for sign out
        NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}