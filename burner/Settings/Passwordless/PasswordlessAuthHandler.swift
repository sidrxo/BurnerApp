//
//  PasswordlessAuthHandler.swift
//  burner
//
//  Created by Sid Rao on 03/11/2025.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Handler for processing passwordless authentication deep links
class PasswordlessAuthHandler: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?
    
    /// Call this from your App or SceneDelegate when handling deep links
    func handleSignInLink(url: URL) -> Bool {
        // Check if this is a sign-in link
        guard Auth.auth().isSignIn(withEmailLink: url.absoluteString) else {
            return false
        }
        
        // Retrieve the email from storage
        guard let email = UserDefaults.standard.string(forKey: "pendingEmailForSignIn") else {
            self.error = "Email not found. Please try signing in again."
            return false
        }
        
        isProcessing = true
        
        // Sign in with the link
        Auth.auth().signIn(withEmail: email, link: url.absoluteString) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.error = "Sign in failed: \(error.localizedDescription)"
                    return
                }
                
                guard let user = authResult?.user else {
                    self.error = "Failed to get user information"
                    return
                }
                
                // Clear the stored email
                UserDefaults.standard.removeObject(forKey: "pendingEmailForSignIn")
                
                // Create or update user profile
                self.createUserProfile(for: user)
                
                // Post notification for successful sign in
                NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            }
        }
        
        return true
    }
    
    /// Create or update user profile in Firestore
    private func createUserProfile(for user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { snapshot, error in
            if error != nil {
                return
            }
            
            let isNewUser = snapshot?.exists != true
            
            var userData: [String: Any] = [
                "lastLoginAt": FieldValue.serverTimestamp(),
                "provider": "emailLink"
            ]
            
            if isNewUser {
                // New user - create full profile
                let displayName = user.email?.components(separatedBy: "@").first ?? "User"
                
                userData.merge([
                    "email": user.email ?? "",
                    "displayName": displayName,
                    "role": "user",
                    "createdAt": FieldValue.serverTimestamp(),
                    "venuePermissions": []
                ]) { _, new in new }
                
                userRef.setData(userData) { error in
                    if let error = error {
                        print("Error creating user profile: \(error.localizedDescription)")
                    }
                }
            } else {
                // Existing user - just update last login
                userRef.updateData(userData) { error in
                    if let error = error {
                        print("Error updating user profile: \(error.localizedDescription)")
                    }
                }
            }
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
