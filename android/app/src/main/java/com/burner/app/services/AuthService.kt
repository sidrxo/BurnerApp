package com.burner.app.services

import android.content.Context
import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.User
import dagger.hilt.android.qualifiers.ApplicationContext
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.providers.builtin.Email
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
    private val auth: Auth get() = supabase.auth

    val currentUserId: String?
        get() = auth.currentUserOrNull()?.id

    fun isAuthenticated(): Boolean = auth.currentUserOrNull() != null

    val authStateFlow: Flow<Boolean> = auth.sessionStatus.map { status ->
        status is SessionStatus.Authenticated
    }

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
            auth.signOut()
        } catch (e: Exception) {
            // Ignore sign out errors
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
            // Log error but don't fail authentication
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
            // Log error but don't fail authentication
            println("Error updating last login: ${e.message}")
        }
    }

    // Get user profile
    suspend fun getUserProfile(userId: String): User? {
        return try {
            val response = supabase.postgrest.from("users")
                .select {
                    filter {
                        eq("id", userId)
                    }
                }
                .decodeSingle<User>()
            response
        } catch (e: RestException) {
            null
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

    // Get user role - from Supabase user metadata or database
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
