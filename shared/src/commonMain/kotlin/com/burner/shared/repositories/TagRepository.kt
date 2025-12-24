package com.burner.shared.repositories

import com.burner.shared.models.Tag

/**
 * Tag Repository
 * Handles all tag/genre-related data operations
 */
class TagRepository(private val supabaseClient: SupabaseClient) {

    /**
     * Fetch all active tags/genres
     */
    suspend fun fetchTags(): Result<List<Tag>> {
        return try {
            val tags = supabaseClient.from("tags")
                .select()
                .eq("active", true)
                .order("order", ascending = true)
                .execute<List<Tag>>()

            // Return default tags if none found
            Result.success(
                if (tags.isEmpty()) Tag.defaultGenres else tags
            )
        } catch (e: Exception) {
            // Return default tags on error
            Result.success(Tag.defaultGenres)
        }
    }

    /**
     * Fetch a specific tag by ID
     */
    suspend fun fetchTag(tagId: String): Result<Tag?> {
        return try {
            val tag = supabaseClient.from("tags")
                .select()
                .eq("id", tagId)
                .executeSingle<Tag>()

            Result.success(tag)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
