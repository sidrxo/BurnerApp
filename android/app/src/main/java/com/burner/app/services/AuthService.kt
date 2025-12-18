package com.burner.app.services

import android.content.Context
import android.content.Intent
import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.User
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import dagger.hilt.android.qualifiers.ApplicationContext
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.providers.Google
import io.github.jan.supabase.gotrue.providers.builtin.Email
import io.github.jan.supabase.gotrue.providers.builtin.IDToken
import io.github.jan.supabase.gotrue.providers.builtin.OTP
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.datetime.Clock
import javax.inject.Inject
import javax.inject.Singleton

sealed class AuthResult {
    data class Success(val userId: String) : AuthResult()
    data class Error(val message: String) : AuthResult()
}

@Singleton
class AuthService @Inject constructor(
    private val supabase: BurnerSupabaseClient,
    @ApplicationContext private val context: Context
) {
    companion object {
        // TODO: Replace with your actual Web Client ID from Google Cloud Console
        // This must be the "Web client" ID, not the Android client ID
        private const val WEB_CLIENT_ID = "8577865405-sbo8kkgat2ngipsrrjr1uh5nhavf9pdq.apps.googleusercontent.com"
    }

    private val auth: Auth get() = supabase.auth

    val currentUserId: String?
        get() = auth.currentUserOrNull()?.id

    fun isAuthenticated(): Boolean = auth.currentUserOrNull() != null

    val authStateFlow: Flow<Boolean> = auth.sessionStatus.map { status ->
        status is SessionStatus.Authenticated
    }

    // --- Google Sign In Implementation ---

    // 1. Get the Intent to launch the Google Sign-In flow
    fun getGoogleSignInIntent(): Intent {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(WEB_CLIENT_ID)
            .requestEmail()
            .build()

        return GoogleSignIn.getClient(context, gso).signInIntent
    }

    // 2. Handle the result (Exchange Google ID Token for Supabase Session)
    suspend fun handleGoogleSignInResult(idToken: String): AuthResult {
        return try {
            // Sign in to Supabase using the Google ID Token
            auth.signInWith(IDToken) {
                this.idToken = idToken
                this.provider = Google
            }

            val userId = auth.currentUserOrNull()?.id
            if (userId != null) {
                // Check if we need to create a profile, or just update login time
                val existingProfile = getUserProfile(userId)
                if (existingProfile == null) {
                    val email = auth.currentUserOrNull()?.email ?: ""
                    createUserProfile(userId, email, "google")
                } else {
                    updateLastLogin(userId)
                }
                AuthResult.Success(userId)
            } else {
                AuthResult.Error("Google sign in failed: No user ID returned")
            }
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Google sign in failed")
        }
    }

    // --- Passwordless Auth (OTP) Implementation ---

    // Send OTP magic link to email
    // Authentication happens automatically when user clicks the link (via deep linking)
    // No manual verification needed - Supabase handles it automatically
    suspend fun sendMagicLink(email: String): AuthResult {
        return try {
            auth.signInWith(OTP) {
                this.email = email
                this.createUser = true
                // Redirect URL for deep linking - matches iOS
                // Supports both custom scheme (burner://auth) and web URL for App Links
                this.redirectTo = java.net.URL("https://manageburner.online/signin")
            }
            AuthResult.Success("OTP sent")
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Failed to send magic link")
        }
    }

    // --- Existing Methods ---

    // Email/Password Sign Up
    suspend fun signUpWithEmail(email: String, password: String): AuthResult {
        return try {
            auth.signUpWith(Email) {
                this.email = email
                this.password = password
            }

            val userId = auth.currentUserOrNull()?.id
            if (userId != null) {
                createUserProfile(userId, email, "email")
                AuthResult.Success(userId)
            } else {
                AuthResult.Error("Failed to create account")
            }
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Sign up failed")
        }
    }

    // Email/Password Sign In
    suspend fun signInWithEmail(email: String, password: String): AuthResult {
        return try {
            auth.signInWith(Email) {
                this.email = email
                this.password = password
            }

            val userId = auth.currentUserOrNull()?.id
            if (userId != null) {
                updateLastLogin(userId)
                AuthResult.Success(userId)
            } else {
                AuthResult.Error("Failed to sign in")
            }
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Sign in failed")
        }
    }

    // Sign Out
    suspend fun signOut() {
        try {
            // Also sign out of Google to allow account switching
            GoogleSignIn.getClient(context, GoogleSignInOptions.DEFAULT_SIGN_IN).signOut()
            auth.signOut()
        } catch (e: Exception) {
            // Ignore errors
        }
    }

    // Password Reset
    suspend fun sendPasswordReset(email: String): Result<Unit> {
        return try {
            auth.resetPasswordForEmail(email)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Create user profile in Supabase
    private suspend fun createUserProfile(userId: String, email: String, provider: String) {
        try {
            val now = Clock.System.now().toString()
            val userDoc = mapOf(
                "id" to userId,
                "email" to email,
                "provider" to provider,
                "created_at" to now,
                "last_login_at" to now,
                "role" to "user"
            )

            supabase.postgrest.from("users")
                .insert(userDoc)
        } catch (e: Exception) {
            println("Error creating user profile: ${e.message}")
        }
    }

    // Update last login timestamp
    private suspend fun updateLastLogin(userId: String) {
        try {
            val now = Clock.System.now().toString()
            supabase.postgrest.from("users")
                .update({
                    set("last_login_at", now)
                }) {
                    filter {
                        eq("id", userId)
                    }
                }
        } catch (e: Exception) {
            println("Error updating last login: ${e.message}")
        }
    }

    // Get user profile
    suspend fun getUserProfile(userId: String): User? {
        return try {
            supabase.postgrest.from("users")
                .select {
                    filter {
                        eq("id", userId)
                    }
                }
                .decodeSingle<User>()
        } catch (e: Exception) {
            null
        }
    }

    // Update user profile
    suspend fun updateUserProfile(userId: String, updates: Map<String, Any>): Result<Unit> {
        return try {
            supabase.postgrest.from("users")
                .update(updates) {
                    filter {
                        eq("id", userId)
                    }
                }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Get user role
    suspend fun getUserRole(): String? {
        return try {
            val userId = currentUserId ?: return null
            val user = getUserProfile(userId)
            user?.role
        } catch (e: Exception) {
            null
        }
    }
}