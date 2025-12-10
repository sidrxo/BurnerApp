package com.burner.app.data.repository

import android.util.Log
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.burner.app.data.models.Event
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.util.Calendar
import java.util.Date
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EventRepository @Inject constructor(
    private val firestore: FirebaseFirestore
) {
    private val eventsCollection = firestore.collection("events")

    // Get all events (real-time) - matching iOS behavior (events from 7 days ago)
    val allEvents: Flow<List<Event>> = callbackFlow {
        // Match iOS: fetch events from 7 days ago to show recently started events
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -7)
        val sevenDaysAgo = calendar.time

        Log.d("EventRepository", "Setting up real-time listener for events since: $sevenDaysAgo")

        val listener = eventsCollection
            .whereGreaterThanOrEqualTo("startTime", Timestamp(sevenDaysAgo))
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e("EventRepository", "Error fetching events: ${error.message}")
                    // Don't close the flow on error, just log and continue
                    trySend(emptyList())
                    return@addSnapshotListener
                }

                val events = snapshot?.documents?.mapNotNull { doc ->
                    try {
                        doc.toObject(Event::class.java)
                    } catch (e: Exception) {
                        Log.e("EventRepository", "Error parsing event ${doc.id}: ${e.message}")
                        null
                    }
                } ?: emptyList()

                Log.d("EventRepository", "Received ${events.size} events from Firestore")
                trySend(events)
            }

        awaitClose {
            Log.d("EventRepository", "Removing events listener")
            listener.remove()
        }
    }

    // Get featured events
    suspend fun getFeaturedEvents(limit: Int = 5): List<Event> {
        return try {
            eventsCollection
                .whereEqualTo("isFeatured", true)
                .whereGreaterThan("startTime", Timestamp.now())
                .orderBy("startTime", Query.Direction.ASCENDING)
                .limit(limit.toLong())
                .get()
                .await()
                .documents
                .mapNotNull { it.toObject(Event::class.java) }
                .shuffled() // Shuffle like iOS does
        } catch (e: Exception) {
            emptyList()
        }
    }

    // Get events this week
    suspend fun getThisWeekEvents(limit: Int = 10): List<Event> {
        val calendar = Calendar.getInstance()
        val now = calendar.time
        calendar.add(Calendar.DAY_OF_YEAR, 7)
        val oneWeekLater = calendar.time

        return try {
            eventsCollection
                .whereGreaterThan("startTime", Timestamp(now))
                .whereLessThan("startTime", Timestamp(oneWeekLater))
                .orderBy("startTime", Query.Direction.ASCENDING)
                .limit(limit.toLong())
                .get()
                .await()
                .documents
                .mapNotNull { it.toObject(Event::class.java) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    // Get nearby events (within radius in km)
    suspend fun getNearbyEvents(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 50.0,
        limit: Int = 10
    ): List<Event> {
        // Firestore doesn't support geo queries natively, so we fetch and filter
        return try {
            val events = eventsCollection
                .whereGreaterThan("startTime", Timestamp.now())
                .orderBy("startTime", Query.Direction.ASCENDING)
                .limit(100) // Fetch more to filter
                .get()
                .await()
                .documents
                .mapNotNull { it.toObject(Event::class.java) }

            events.filter { event ->
                event.distanceFrom(latitude, longitude)?.let { distance ->
                    distance <= radiusKm
                } ?: false
            }
                .sortedBy { it.distanceFrom(latitude, longitude) }
                .take(limit)
        } catch (e: Exception) {
            emptyList()
        }
    }

    // Get events by genre/tag
    suspend fun getEventsByGenre(genre: String, limit: Int = 20): List<Event> {
        return try {
            eventsCollection
                .whereArrayContains("tags", genre)
                .whereGreaterThan("startTime", Timestamp.now())
                .orderBy("startTime", Query.Direction.ASCENDING)
                .limit(limit.toLong())
                .get()
                .await()
                .documents
                .mapNotNull { it.toObject(Event::class.java) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    // Search events
    suspend fun searchEvents(
        query: String,
        sortBy: SearchSortOption = SearchSortOption.DATE,
        userLat: Double? = null,
        userLon: Double? = null
    ): List<Event> {
        return try {
            val events = eventsCollection
                .whereGreaterThan("startTime", Timestamp.now())
                .orderBy("startTime", Query.Direction.ASCENDING)
                .limit(100)
                .get()
                .await()
                .documents
                .mapNotNull { it.toObject(Event::class.java) }

            // Filter by query (search in name, venue, description, tags)
            val filtered = if (query.isBlank()) {
                events
            } else {
                val lowercaseQuery = query.lowercase()
                events.filter { event ->
                    event.name.lowercase().contains(lowercaseQuery) ||
                    event.venue.lowercase().contains(lowercaseQuery) ||
                    event.description?.lowercase()?.contains(lowercaseQuery) == true ||
                    event.tags?.any { it.lowercase().contains(lowercaseQuery) } == true
                }
            }

            // Sort
            when (sortBy) {
                SearchSortOption.DATE -> filtered.sortedBy { it.startTime?.toDate() }
                SearchSortOption.PRICE -> filtered.sortedBy { it.price }
                SearchSortOption.NEARBY -> {
                    if (userLat != null && userLon != null) {
                        filtered.sortedBy { it.distanceFrom(userLat, userLon) ?: Double.MAX_VALUE }
                    } else {
                        filtered
                    }
                }
            }.take(10)
        } catch (e: Exception) {
            emptyList()
        }
    }

    // Get single event by ID
    suspend fun getEvent(eventId: String): Event? {
        return try {
            eventsCollection
                .document(eventId)
                .get()
                .await()
                .toObject(Event::class.java)
        } catch (e: Exception) {
            null
        }
    }

    // Get event (real-time)
    fun getEventFlow(eventId: String): Flow<Event?> = callbackFlow {
        val listener = eventsCollection
            .document(eventId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    trySend(null)
                    return@addSnapshotListener
                }
                trySend(snapshot?.toObject(Event::class.java))
            }

        awaitClose { listener.remove() }
    }
}

enum class SearchSortOption {
    DATE,
    PRICE,
    NEARBY
}
