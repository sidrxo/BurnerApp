package com.burner.app.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.burner.app.data.models.Tag
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TagRepository @Inject constructor(
    private val firestore: FirebaseFirestore
) {
    private val tagsCollection = firestore.collection("tags")

    // Get all active tags (real-time)
    val allTags: Flow<List<Tag>> = callbackFlow {
        val listener = tagsCollection
            .whereEqualTo("active", true)
            .orderBy("order", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    // Fall back to default genres
                    trySend(Tag.defaultGenres)
                    return@addSnapshotListener
                }

                val tags = snapshot?.documents?.mapNotNull { doc ->
                    doc.toObject(Tag::class.java)
                } ?: emptyList()

                // Use default genres if none found
                trySend(tags.ifEmpty { Tag.defaultGenres })
            }

        awaitClose { listener.remove() }
    }

    // Get tags once
    suspend fun getTags(): List<Tag> {
        return try {
            tagsCollection
                .whereEqualTo("active", true)
                .orderBy("order", Query.Direction.ASCENDING)
                .get()
                .await()
                .documents
                .mapNotNull { it.toObject(Tag::class.java) }
                .ifEmpty { Tag.defaultGenres }
        } catch (e: Exception) {
            Tag.defaultGenres
        }
    }
}
