package com.burner.shared.services

import com.burner.shared.models.User
import kotlinx.datetime.Clock

/**
 * Authentication Service
 * Handles user authentication and session management
 * Based on iOS AuthenticationService
 */
class AuthService(
    private val authClient: AuthClient,
    private val userRepository: com.burner.shared.repositories.UserRepository
) {
    /**
     * Sign in with email and password
     */
    suspend fun signInWithEmail(email: String, password: String): AuthResult {
        return try {
            val session = authClient.signIn(email, password)
            val userId = session.userId

            // Update last login
            val now = Clock.System.now().toString()
            userRepository.updateUserProfile(
                userId,
                mapOf("last_login_at" to now)
            )

            AuthResult.Success(userId)
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Sign in failed")
        }
    }

    /**
     * Sign up with email and password
     */
    suspend fun signUpWithEmail(
        email: String,
        password: String,
        displayName: String
    ): AuthResult {
        return try {
            val session = authClient.signUp(email, password, displayName)
            val userId = session.userId

            AuthResult.Success(userId)
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Sign up failed")
        }
    }

    /**
     * Sign out current user
     */
    suspend fun signOut(): Result<Unit> {
        return try {
            authClient.signOut()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Send password reset email
     */
    suspend fun resetPassword(email: String): Result<Unit> {
        return try {
            authClient.resetPasswordForEmail(email)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get current user ID
     */
    fun getCurrentUserId(): String? {
        return authClient.getCurrentUserId()
    }

    /**
     * Check if user is authenticated
     */
    fun isAuthenticated(): Boolean {
        return authClient.isAuthenticated()
    }

    /**
     * Get user profile
     */
    suspend fun getUserProfile(): Result<User?> {
        val userId = getCurrentUserId() ?: return Result.success(null)
        return userRepository.fetchUserProfile(userId)
    }

    /**
     * Get user role
     */
    suspend fun getUserRole(): Result<String?> {
        return try {
            val profile = getUserProfile().getOrNull()
            Result.success(profile?.role)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Check if user has a specific role
     */
    suspend fun hasRole(role: String): Result<Boolean> {
        return try {
            val userRole = getUserRole().getOrNull()
            Result.success(userRole == role)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Check if user has any of the specified roles
     */
    suspend fun hasAnyRole(roles: List<String>): Result<Boolean> {
        return try {
            val userRole = getUserRole().getOrNull() ?: return Result.success(false)
            Result.success(roles.contains(userRole))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

/**
 * Auth result sealed class
 */
sealed class AuthResult {
    data class Success(val userId: String) : AuthResult()
    data class Error(val message: String) : AuthResult()
}

/**
 * Auth session data
 */
data class AuthSession(
    val userId: String,
    val email: String
)

/**
 * Platform-specific auth client
 * Implementations will be provided for iOS and Android
 */
expect class AuthClient {
    suspend fun signIn(email: String, password: String): AuthSession
    suspend fun signUp(email: String, password: String, displayName: String): AuthSession
    suspend fun signOut()
    suspend fun resetPasswordForEmail(email: String)
    fun getCurrentUserId(): String?
    fun isAuthenticated(): Boolean
}
