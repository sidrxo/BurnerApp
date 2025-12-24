package com.burner.shared.repositories

import com.burner.shared.models.User
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from

/**
 * User Repository
 * Handles all user-related data operations
 */
class UserRepository(private val client: SupabaseClient) {

    /**
     * Fetch user profile by ID
     */
    suspend fun fetchUserProfile(userId: String): Result<User?> {
        return try {
            val user = client.from("users").select {
                filter {
                    eq("id", userId)
                }
            }.decodeSingleOrNull<User>()

            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Update user profile
     */
    suspend fun updateUserProfile(userId: String, data: Map<String, Any>): Result<Unit> {
        return try {
            client.from("users").update(data) {
                filter {
                    eq("id", userId)
                }
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Create user profile
     */
    suspend fun createUserProfile(user: User): Result<Unit> {
        return try {
            client.from("users").upsert(user)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Check if user exists
     */
    suspend fun userExists(userId: String): Result<Boolean> {
        return try {
            val user = fetchUserProfile(userId).getOrNull()
            Result.success(user != null)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}