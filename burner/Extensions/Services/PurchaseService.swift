import Foundation
import FirebaseAuth
import FirebaseFunctions
import Combine

// MARK: - Purchase Service
class PurchaseService: Sendable {
    private let functions: Functions
    
    init() {
        #if DEBUG
        // Configure for local development if needed
        // functions = Functions.functions()
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif
        
        self.functions = Functions.functions(region: "us-central1")
    }
    
    // MARK: - Purchase Ticket Result
    struct PurchaseResult: Sendable {
        let success: Bool
        let message: String
    }
    
    // MARK: - Purchase Ticket
    func purchaseTicket(eventId: String) async throws -> PurchaseResult {
        guard let user = Auth.auth().currentUser else {
            return PurchaseResult(success: false, message: "Please log in to purchase a ticket")
        }
        
        // Get fresh ID token
        let token = try await user.getIDTokenForcingRefresh(true, completion: <#((String?, (any Error)?) -> Void)?#>)
        
        guard token != nil else {
            return PurchaseResult(success: false, message: "Failed to get authentication token")
        }
        
        // Call Cloud Function
        let purchaseData: [String: Any] = ["eventId": eventId]
        
        return try await withCheckedThrowingContinuation { continuation in
            functions.httpsCallable("purchaseTicket").call(purchaseData) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = result?.data as? [String: Any] else {
                    continuation.resume(
                        returning: PurchaseResult(
                            success: false,
                            message: "Unexpected response from server"
                        )
                    )
                    return
                }
                
                let success = data["success"] as? Bool ?? false
                let message = data["message"] as? String ?? (success ? "Ticket purchased successfully!" : "Purchase failed")
                
                continuation.resume(
                    returning: PurchaseResult(success: success, message: message)
                )
            }
        }
    }
}

// MARK: - Authentication Service
@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepository
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        setupAuthListener()
    }
    
    // Convenience init for default usage
    convenience init() {
        self.init(userRepository: UserRepository())
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Setup Auth Listener
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        try await user.delete()
        currentUser = nil
    }
    
    // MARK: - Create User Profile
    func createOrUpdateUserProfile(
        user: User,
        provider: String,
        displayName: String?,
        email: String?
    ) async throws {
        let userExists = try await userRepository.userExists(userId: user.uid)
        
        var userData: [String: Any] = [
            "lastLoginAt": Date(),
            "provider": provider
        ]
        
        if !userExists {
            // Create new profile
            let profile = UserProfile(
                email: email ?? user.email ?? "",
                displayName: displayName ?? user.displayName ?? "",
                role: "user",
                provider: provider,
                venuePermissions: [],
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            try await userRepository.createUserProfile(userId: user.uid, profile: profile)
        } else {
            // Update existing profile
            try await userRepository.updateUserProfile(userId: user.uid, data: userData)
        }
    }
    
    // MARK: - Fetch User Role
    func fetchUserRole() async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            return "user"
        }
        
        let profile = try await userRepository.fetchUserProfile(userId: userId)
        return profile?.role ?? "user"
    }
}

// MARK: - Error Handling Service
class ErrorHandlingService {
    enum AppError: LocalizedError {
        case networkError(String)
        case authenticationError(String)
        case dataError(String)
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "Network Error: \(message)"
            case .authenticationError(let message):
                return "Authentication Error: \(message)"
            case .dataError(let message):
                return "Data Error: \(message)"
            case .unknownError:
                return "An unknown error occurred"
            }
        }
    }
    
    // MARK: - Handle Error
    static func handleError(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "Unknown error"
        }
        
        if let nsError = error as NSError? {
            // Firebase Functions errors
            if nsError.domain == "com.firebase.functions" {
                return handleFunctionsError(nsError)
            }
            
            // Firestore errors
            if nsError.domain == "FIRFirestoreErrorDomain" {
                return handleFirestoreError(nsError)
            }
            
            // Auth errors
            if nsError.domain == AuthErrorDomain {
                return handleAuthError(nsError)
            }
        }
        
        return error.localizedDescription
    }
    
    // MARK: - Handle Functions Error
    private static func handleFunctionsError(_ error: NSError) -> String {
        switch error.code {
        case FunctionsErrorCode.unauthenticated.rawValue:
            return "Authentication failed. Please log out and log back in."
        case FunctionsErrorCode.permissionDenied.rawValue:
            return "Permission denied. Please check your account."
        case FunctionsErrorCode.notFound.rawValue:
            return "Resource not found."
        case FunctionsErrorCode.invalidArgument.rawValue:
            return "Invalid request. Please try again."
        case FunctionsErrorCode.failedPrecondition.rawValue:
            return error.localizedDescription
        case FunctionsErrorCode.internal.rawValue:
            return "Server error. Please try again."
        case FunctionsErrorCode.unavailable.rawValue:
            return "Service temporarily unavailable. Please try again."
        case FunctionsErrorCode.deadlineExceeded.rawValue:
            return "Request timed out. Please try again."
        default:
            return error.localizedDescription
        }
    }
    
    // MARK: - Handle Firestore Error
    private static func handleFirestoreError(_ error: NSError) -> String {
        switch error.code {
        case 7: // Permission denied
            return "You don't have permission to access this data."
        case 14: // Unavailable
            return "Service temporarily unavailable. Please check your connection."
        default:
            return "Database error. Please try again."
        }
    }
    
    // MARK: - Handle Auth Error
    private static func handleAuthError(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.userNotFound.rawValue:
            return "User not found."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password."
        default:
            return "Authentication error. Please try again."
        }
    }
}
