package com.burner.shared.repositories

import com.burner.shared.models.User

/**
 * User Repository
 * Handles all user-related data operations
 * Based on iOS UserRepository implementation
 */
class UserRepository(private val supabaseClient: SupabaseClient) {

    /**
     * Fetch user profile by ID
     */
    suspend fun fetchUserProfile(userId: String): Result<User?> {
        return try {
            val user = supabaseClient.from("users")
                .select()
                .eq("id", userId)
                .executeSingle<User>()

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
            supabaseClient.from("users")
                .update(data)
                .eq("id", userId)
                .execute<Unit>()

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
            supabaseClient.from("users")
                .upsert(user)
                .execute<Unit>()

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

/**
 * Extension for update operations
 */
expect fun QueryBuilder.update(data: Map<String, Any>): QueryBuilder

/**
 * Extension for upsert operations
 */
expect fun QueryBuilder.upsert(data: Any): QueryBuilder
