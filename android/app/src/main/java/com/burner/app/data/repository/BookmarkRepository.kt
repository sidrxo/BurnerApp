package com.burner.app.data.repository

import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.Bookmark
import com.burner.app.data.models.Event
import com.burner.app.services.AuthService
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BookmarkRepository @Inject constructor(
    private val supabase: BurnerSupabaseClient,
    private val authService: AuthService
) {
    // Get user's bookmarks (real-time)
    fun getUserBookmarks(): Flow<List<Bookmark>> {
        val userId = authService.currentUserId
        if (userId == null) {
            return flowOf(emptyList())
        }

        val channel = supabase.realtime.channel("bookmarks_$userId")

        return channel
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "bookmarks"
                filter = "user_id=eq.$userId"
            }
            .map {
                getUserBookmarksList(userId)
            }
            .onStart {
                // Subscribe to the channel and emit initial data
                channel.subscribe()
                emit(getUserBookmarksList(userId))
            }
    }

    private suspend fun getUserBookmarksList(userId: String): List<Bookmark> {
        return try {
            supabase.postgrest.from("bookmarks")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("user_id", userId)
                    }
                    order("bookmarked_at", Order.DESCENDING)
                }
                .decodeList<Bookmark>()
        } catch (e: Exception) {
            emptyList()
        }
    }

    // Get bookmarked event IDs (for quick lookup)
    fun getBookmarkedEventIds(): Flow<Set<String>> {
        val userId = authService.currentUserId
        if (userId == null) {
            return flowOf(emptySet())
        }

        return getUserBookmarks().map { bookmarks ->
            bookmarks.map { it.eventId }.toSet()
        }
    }

    // Check if event is bookmarked
    suspend fun isBookmarked(eventId: String): Boolean {
        val userId = authService.currentUserId ?: return false

        return try {
            val result = supabase.postgrest.from("bookmarks")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("user_id", userId)
                        eq("event_id", eventId)
                    }
                    limit(1)
                }
                .decodeList<Bookmark>()
            result.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    // Add bookmark
    suspend fun addBookmark(event: Event): Result<Unit> {
        val userId = authService.currentUserId
            ?: return Result.failure(Exception("User not authenticated"))

        val eventId = event.id
            ?: return Result.failure(Exception("Event ID is null"))

        return try {
            val bookmark = Bookmark.fromEvent(event)
            val bookmarkData = mapOf(
                "user_id" to userId,
                "event_id" to bookmark.eventId,
                "event_name" to bookmark.eventName,
                "venue" to bookmark.eventVenue,
                "start_time" to bookmark.startTime,
                "event_price" to bookmark.eventPrice,
                "event_image_url" to bookmark.eventImageUrl,
                "bookmarked_at" to bookmark.bookmarkedAt
            )

            supabase.postgrest.from("bookmarks")
                .insert(bookmarkData)

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Remove bookmark
    suspend fun removeBookmark(eventId: String): Result<Unit> {
        val userId = authService.currentUserId
            ?: return Result.failure(Exception("User not authenticated"))

        return try {
            supabase.postgrest.from("bookmarks")
                .delete {
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

    // Toggle bookmark
    suspend fun toggleBookmark(event: Event): Result<Boolean> {
        val eventId = event.id ?: return Result.failure(Exception("Event ID is null"))

        return try {
            val isCurrentlyBookmarked = isBookmarked(eventId)

            if (isCurrentlyBookmarked) {
                removeBookmark(eventId)
                Result.success(false) // Now not bookmarked
            } else {
                addBookmark(event)
                Result.success(true) // Now bookmarked
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}