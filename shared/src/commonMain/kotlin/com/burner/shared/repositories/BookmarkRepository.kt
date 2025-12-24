package com.burner.shared.repositories

import com.burner.shared.models.Bookmark
import com.burner.shared.models.Event
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.datetime.Clock

/**
 * Bookmark Repository
 * Handles all bookmark-related data operations
 */
class BookmarkRepository(private val client: SupabaseClient) {

    /**
     * Fetch all bookmarks for a user
     */
    suspend fun fetchBookmarks(userId: String): Result<List<Bookmark>> {
        return try {
            val bookmarks = client.from("bookmarks").select {
                filter {
                    eq("user_id", userId)
                }
            }.decodeList<Bookmark>()

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
            // Using a Map for insertion is supported by Supabase KMP
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

            client.from("bookmarks").insert(bookmark)
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
            client.from("bookmarks").delete {
                filter {
                    eq("user_id", userId)
                    eq("event_id", eventId)
                }
            }
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
            val count = client.from("bookmarks").select {
                count(io.github.jan.supabase.postgrest.query.Count.EXACT)
                filter {
                    eq("user_id", userId)
                    eq("event_id", eventId)
                }
            }.countOrNull() ?: 0

            Result.success(count > 0)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}