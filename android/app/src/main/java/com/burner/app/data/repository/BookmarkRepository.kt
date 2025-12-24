package com.burner.app.data.repository

import android.util.Log
import com.burner.app.data.BurnerSupabaseClient
import com.burner.shared.models.Bookmark
import com.burner.shared.models.Event
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
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.onStart
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID
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
            Log.w("BookmarkRepo", "User not logged in, returning empty flow")
            return flowOf(emptyList())
        }

        // Unique ID prevents channel conflicts
        val uniqueChannelId = "bookmarks_${userId}_${UUID.randomUUID()}"
        Log.d("BookmarkRepo", "🔌 Connecting to Realtime Channel: $uniqueChannelId")

        return supabase.realtime.channel(uniqueChannelId)
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "bookmarks"
                filter = "user_id=eq.$userId"
            }
            .onEach { action ->
                // THIS IS THE KEY DEBUGGING PART
                Log.d("BookmarkRepo", "🔥 REALTIME EVENT RECEIVED! Action: $action")
                when (action) {
                    is PostgresAction.Insert -> Log.d("BookmarkRepo", "➕ Insert Detected: ${action.record}")
                    is PostgresAction.Delete -> Log.d("BookmarkRepo", "➖ Delete Detected: ${action.oldRecord}")
                    is PostgresAction.Update -> Log.d("BookmarkRepo", "🔄 Update Detected")
                    else -> Log.d("BookmarkRepo", "❓ Unknown Action")
                }
            }
            .map {
                Log.d("BookmarkRepo", "📥 Fetching fresh list from database...")
                getUserBookmarksList(userId)
            }
            .onStart {
                Log.d("BookmarkRepo", "🚀 Flow started - Initial Fetch")
                emit(getUserBookmarksList(userId))
            }
    }

    private suspend fun getUserBookmarksList(userId: String): List<Bookmark> {
        return try {
            val result = supabase.postgrest.from("bookmarks")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("user_id", userId)
                    }
                    order("bookmarked_at", Order.DESCENDING)
                }
                .decodeList<Bookmark>()

            Log.d("BookmarkRepo", "✅ Successfully fetched ${result.size} bookmarks")
            result
        } catch (e: Exception) {
            Log.e("BookmarkRepo", "❌ FAILED to fetch bookmarks list", e)
            emptyList()
        }
    }

    // Get bookmarked event IDs (for quick lookup)
    fun getBookmarkedEventIds(): Flow<Set<String>> {
        return getUserBookmarks().map { bookmarks ->
            bookmarks.map { it.eventId }.toSet()
        }
    }

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

    suspend fun addBookmark(event: Event): Result<Unit> {
        val userId = authService.currentUserId ?: return Result.failure(Exception("No user"))
        val eventId = event.id ?: return Result.failure(Exception("No ID"))

        return try {
            val insertData = BookmarkInsert(
                userId = userId,
                eventId = eventId,
                eventName = event.name,
                venue = event.venue,
                startTime = event.startTime,
                eventPrice = event.price,
                eventImageUrl = event.imageUrl,
                bookmarkedAt = java.time.Instant.now().toString()
            )

            Log.d("BookmarkRepo", "📤 Attempting to INSERT bookmark for event: ${event.name}")
            supabase.postgrest.from("bookmarks").insert(insertData)
            Log.d("BookmarkRepo", "✅ INSERT Success")

            Result.success(Unit)
        } catch (e: Exception) {
            Log.e("BookmarkRepo", "❌ INSERT Failed", e)
            Result.failure(e)
        }
    }

    suspend fun removeBookmark(eventId: String): Result<Unit> {
        val userId = authService.currentUserId ?: return Result.failure(Exception("No user"))
        return try {
            Log.d("BookmarkRepo", "🗑️ Attempting to DELETE bookmark: $eventId")
            supabase.postgrest.from("bookmarks").delete {
                filter {
                    eq("user_id", userId)
                    eq("event_id", eventId)
                }
            }
            Log.d("BookmarkRepo", "✅ DELETE Success")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e("BookmarkRepo", "❌ DELETE Failed", e)
            Result.failure(e)
        }
    }

    suspend fun toggleBookmark(event: Event): Result<Boolean> {
        val eventId = event.id ?: return Result.failure(Exception("No ID"))
        return try {
            if (isBookmarked(eventId)) {
                removeBookmark(eventId)
                Result.success(false)
            } else {
                addBookmark(event)
                Result.success(true)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

@Serializable
private data class BookmarkInsert(
    @SerialName("user_id") val userId: String,
    @SerialName("event_id") val eventId: String,
    @SerialName("event_name") val eventName: String,
    @SerialName("venue") val venue: String,
    @SerialName("start_time") val startTime: String?,
    @SerialName("event_price") val eventPrice: Double,
    @SerialName("event_image_url") val eventImageUrl: String,
    @SerialName("bookmarked_at") val bookmarkedAt: String?
)