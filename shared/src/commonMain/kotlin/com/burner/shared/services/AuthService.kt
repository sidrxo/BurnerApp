package com.burner.shared.services

import com.burner.shared.models.User
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.builtin.Email
import kotlinx.datetime.Clock
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class AuthService(
    private val client: SupabaseClient,
    private val userRepository: com.burner.shared.repositories.UserRepository
) {
    @Throws(Exception::class)
    suspend fun signInWithEmail(email: String, password: String): String {
        client.auth.signInWith(Email) {
            this.email = email
            this.password = password
        }

        val currentUser = client.auth.currentUserOrNull()
        val userId = currentUser?.id ?: throw Exception("User not found after login")

        // Update last login (Fire and forget, or await if strict)
        try {
            val now = Clock.System.now().toString()
            userRepository.updateUserProfile(
                userId,
                mapOf("last_login_at" to now)
            )
        } catch (e: Exception) {
            // Ignore analytics errors
        }

        return userId
    }

    @Throws(Exception::class)
    suspend fun signUpWithEmail(email: String, password: String, displayName: String): String {
        client.auth.signUpWith(Email) {
            this.email = email
            this.password = password
            data = buildJsonObject {
                put("full_name", displayName)
            }
        }
        return client.auth.currentUserOrNull()?.id ?: throw Exception("Signup failed")
    }

    @Throws(Exception::class)
    suspend fun signOut() {
        client.auth.signOut()
    }

    @Throws(Exception::class)
    suspend fun resetPassword(email: String) {
        client.auth.resetPasswordForEmail(email)
    }

    fun getCurrentUserId(): String? {
        return client.auth.currentUserOrNull()?.id
    }

    fun isAuthenticated(): Boolean {
        return client.auth.currentUserOrNull() != null
    }
}