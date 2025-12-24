package com.burner.shared.services

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.builtin.Email

/**
 * iOS implementation of AuthClient using Supabase KMP SDK
 */
actual class AuthClient {
    private val client: SupabaseClient

    constructor(supabaseClient: SupabaseClient) {
        this.client = supabaseClient
    }

    actual suspend fun signIn(email: String, password: String): AuthSession {
        val response = client.auth.signInWith(Email) {
            this.email = email
            this.password = password
        }

        val userId = response.user?.id ?: throw Exception("No user ID returned")
        val userEmail = response.user?.email ?: email

        return AuthSession(userId, userEmail)
    }

    actual suspend fun signUp(email: String, password: String, displayName: String): AuthSession {
        val response = client.auth.signUpWith(Email) {
            this.email = email
            this.password = password
            data = mapOf("display_name" to displayName)
        }

        val userId = response.user?.id ?: throw Exception("No user ID returned")
        val userEmail = response.user?.email ?: email

        return AuthSession(userId, userEmail)
    }

    actual suspend fun signOut() {
        client.auth.signOut()
    }

    actual suspend fun resetPasswordForEmail(email: String) {
        client.auth.resetPasswordForEmail(email)
    }

    actual fun getCurrentUserId(): String? {
        return client.auth.currentUserOrNull()?.id
    }

    actual fun isAuthenticated(): Boolean {
        return client.auth.currentSessionOrNull() != null
    }
}
