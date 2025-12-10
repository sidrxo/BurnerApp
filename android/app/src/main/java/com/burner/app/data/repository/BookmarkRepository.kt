package com.burner.app.data.repository

import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.burner.app.data.models.Bookmark
import com.burner.app.data.models.Event
import com.burner.app.services.AuthService
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BookmarkRepository @Inject constructor(
    private val firestore: FirebaseFirestore,
    private val authService: AuthService
) {
    // Get user's bookmarks subcollection path
    private fun getBookmarksCollection(userId: String) =
        firestore.collection("users").document(userId).collection("bookmarks")

    // Get user's bookmarks (real-time)
    fun getUserBookmarks(): Flow<List<Bookmark>> = callbackFlow {
        val userId = authService.currentUserId
        if (userId == null) {
            trySend(emptyList())
            close()
            return@callbackFlow
        }

        val listener = getBookmarksCollection(userId)
            .orderBy("bookmarkedAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    trySend(emptyList())
                    return@addSnapshotListener
                }

                val bookmarks = snapshot?.documents?.mapNotNull { doc ->
                    doc.toObject(Bookmark::class.java)
                } ?: emptyList()

                trySend(bookmarks)
            }

        awaitClose { listener.remove() }
    }

    // Get bookmarked event IDs (for quick lookup)
    fun getBookmarkedEventIds(): Flow<Set<String>> = callbackFlow {
        val userId = authService.currentUserId
        if (userId == null) {
            trySend(emptySet())
            close()
            return@callbackFlow
        }

        val listener = getBookmarksCollection(userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    trySend(emptySet())
                    return@addSnapshotListener
                }

                val ids = snapshot?.documents?.mapNotNull { doc ->
                    doc.id
                }?.toSet() ?: emptySet()

                trySend(ids)
            }

        awaitClose { listener.remove() }
    }

    // Check if event is bookmarked
    suspend fun isBookmarked(eventId: String): Boolean {
        val userId = authService.currentUserId ?: return false

        return try {
            getBookmarksCollection(userId)
                .document(eventId)
                .get()
                .await()
                .exists()
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

            getBookmarksCollection(userId)
                .document(eventId)
                .set(bookmark)
                .await()

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
            getBookmarksCollection(userId)
                .document(eventId)
                .delete()
                .await()

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
