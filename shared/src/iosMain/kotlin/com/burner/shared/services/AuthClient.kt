package com.burner.shared.services

/**
 * iOS actual implementation of AuthClient
 * This is a minimal placeholder - the real authentication happens in Swift
 */
actual class AuthClient {
    actual suspend fun signIn(email: String, password: String): AuthSession {
        throw NotImplementedError("Use Swift Supabase auth client directly - KMP auth not needed for iOS")
    }

    actual suspend fun signUp(email: String, password: String, displayName: String): AuthSession {
        throw NotImplementedError("Use Swift Supabase auth client directly - KMP auth not needed for iOS")
    }

    actual suspend fun signOut() {
        throw NotImplementedError("Use Swift Supabase auth client directly - KMP auth not needed for iOS")
    }

    actual suspend fun resetPasswordForEmail(email: String) {
        throw NotImplementedError("Use Swift Supabase auth client directly - KMP auth not needed for iOS")
    }

    actual fun getCurrentUserId(): String? = null

    actual fun isAuthenticated(): Boolean = false
}
