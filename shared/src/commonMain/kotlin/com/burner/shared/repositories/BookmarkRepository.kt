package com.burner.shared.repositories

import com.burner.shared.models.Bookmark
import com.burner.shared.models.Event
import kotlinx.datetime.Clock

/**
 * Bookmark Repository
 * Handles all bookmark-related data operations
 * Based on iOS BookmarkRepository implementation
 */
class BookmarkRepository(private val supabaseClient: SupabaseClient) {

    /**
     * Fetch all bookmarks for a user
     */
    suspend fun fetchBookmarks(userId: String): Result<List<Bookmark>> {
        return try {
            val bookmarks = supabaseClient.from("bookmarks")
                .select()
                .eq("user_id", userId)
                .execute<List<Bookmark>>()

            Result.success(bookmarks)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Add a bookmark for an event
     */
    suspend fun addBookmark(userId: String, event: Event): Result<Unit> {
        return try {
            val bookmark = mapOf(
                "user_id" to userId,
                "event_id" to (event.id ?: ""),
                "event_name" to event.name,
                "venue" to event.venue,
                "start_time" to event.startTime,
                "event_price" to event.price,
                "event_image_url" to event.imageUrl,
                "bookmarked_at" to Clock.System.now().toString()
            )

            supabaseClient.from("bookmarks")
                .insert(bookmark)
                .execute<Unit>()

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Remove a bookmark
     */
    suspend fun removeBookmark(userId: String, eventId: String): Result<Unit> {
        return try {
            supabaseClient.from("bookmarks")
                .delete()
                .eq("user_id", userId)
                .eq("event_id", eventId)
                .execute<Unit>()

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Check if an event is bookmarked
     */
    suspend fun isBookmarked(userId: String, eventId: String): Result<Boolean> {
        return try {
            val bookmarks = supabaseClient.from("bookmarks")
                .select()
                .eq("user_id", userId)
                .eq("event_id", eventId)
                .execute<List<Bookmark>>()

            Result.success(bookmarks.isNotEmpty())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

/**
 * Extension for delete operations
 */
expect fun QueryBuilder.delete(): QueryBuilder

/**
 * Extension for insert operations
 */
expect fun QueryBuilder.insert(data: Map<String, Any?>): QueryBuilder
