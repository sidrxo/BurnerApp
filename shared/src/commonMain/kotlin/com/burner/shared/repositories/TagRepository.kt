package com.burner.shared.repositories

import com.burner.shared.models.Tag
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from

/**
 * Tag Repository
 * Handles fetching event tags
 */
class TagRepository(private val client: SupabaseClient) {

    /**
     * Fetch all available tags
     */
    suspend fun fetchTags(): Result<List<Tag>> {
        return try {
            val tags = client.from("tags").select().decodeList<Tag>()
            Result.success(tags)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Fetch trending tags
     */
    suspend fun fetchTrendingTags(limit: Int = 5): Result<List<Tag>> {
        return try {
            val tags = client.from("tags")
                .select {
                    limit(limit.toLong())
                    // Assuming you might have a 'usage_count' or 'is_trending' column
                    // If not, standard select is fine
                }
                .decodeList<Tag>()

            Result.success(tags)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}