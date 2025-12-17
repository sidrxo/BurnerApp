package com.burner.app.data.repository

import android.util.Log
import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.Event
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.time.Duration.Companion.days

@Singleton
class EventRepository @Inject constructor(
    private val supabase: BurnerSupabaseClient
) {
    // Get all events (real-time)
    val allEvents: Flow<List<Event>> = supabase.realtime
        .channel("events")
        .postgresChangeFlow<PostgresAction>(schema = "public") {
            table = "events"
        }
        .map {
            // When a change happens (Insert/Update/Delete), re-fetch the list
            getAllEvents()
        }
        .onStart {
            // CRITICAL FIX: Fetch the initial data immediately when the flow starts
            emit(getAllEvents())
        }

    // Get all events with filter
    suspend fun getAllEvents(): List<Event> {
        return try {
            val sevenDaysAgo = Clock.System.now() - 7.days

            supabase.postgrest.from("events")
                .select()
                .decodeList<Event>()
                .filter { event ->
                    // Safely parse date, defaulting to false if parsing fails
                    event.startTime?.let {
                        try {
                            Instant.parse(it) >= sevenDaysAgo
                        } catch (e: Exception) {
                            false
                        }
                    } ?: false
                }
                .sortedBy { it.startTime }
        } catch (e: Exception) {
            Log.e("EventRepository", "Error fetching all events", e)
            emptyList()
        }
    }

    // Get featured events
    suspend fun getFeaturedEvents(limit: Int = 5): List<Event> {
        return try {
            val now = Clock.System.now().toString()
            supabase.postgrest.from("events")
                .select() {
                    filter {
                        eq("is_featured", true)
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(limit.toLong())
                }
                .decodeList<Event>()
                .shuffled()
        } catch (e: Exception) {
            Log.e("EventRepository", "Error fetching featured events", e)
            emptyList()
        }
    }

    // Get events this week
    suspend fun getThisWeekEvents(limit: Int = 10): List<Event> {
        val now = Clock.System.now()
        val oneWeekLater = now + 7.days

        return try {
            supabase.postgrest.from("events")
                .select() {
                    filter {
                        gt("start_time", now.toString())
                        lt("start_time", oneWeekLater.toString())
                    }
                    order("start_time", Order.ASCENDING)
                    limit(limit.toLong())
                }
                .decodeList<Event>()
        } catch (e: Exception) {
            Log.e("EventRepository", "Error fetching this week events", e)
            emptyList()
        }
    }

    // Get nearby events
    suspend fun getNearbyEvents(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 50.0,
        limit: Int = 10
    ): List<Event> {
        return try {
            val now = Clock.System.now().toString()
            val events = supabase.postgrest.from("events")
                .select() {
                    filter {
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(100)
                }
                .decodeList<Event>()

            events.filter { event ->
                event.distanceFrom(latitude, longitude)?.let { distance ->
                    distance <= radiusKm
                } ?: false
            }
                .sortedBy { it.distanceFrom(latitude, longitude) }
                .take(limit)
        } catch (e: Exception) {
            Log.e("EventRepository", "Error fetching nearby events", e)
            emptyList()
        }
    }

    // Get events by genre/tag
    suspend fun getEventsByGenre(genre: String, limit: Int = 20): List<Event> {
        return try {
            val now = Clock.System.now().toString()
            supabase.postgrest.from("events")
                .select() {
                    filter {
                        contains("tags", listOf(genre))
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(limit.toLong())
                }
                .decodeList<Event>()
        } catch (e: Exception) {
            Log.e("EventRepository", "Error fetching events by genre", e)
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
            val now = Clock.System.now().toString()
            val events = supabase.postgrest.from("events")
                .select() {
                    filter {
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(100)
                }
                .decodeList<Event>()

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

            when (sortBy) {
                SearchSortOption.DATE -> filtered.sortedBy { it.startDate }
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
            Log.e("EventRepository", "Error searching events", e)
            emptyList()
        }
    }

    // Get single event by ID
    suspend fun getEvent(eventId: String): Event? {
        return try {
            supabase.postgrest.from("events")
                .select() {
                    filter {
                        eq("id", eventId)
                    }
                }
                .decodeSingle<Event>()
        } catch (e: Exception) {
            Log.e("EventRepository", "Error fetching event $eventId", e)
            null
        }
    }

    // Get event (real-time)
    fun getEventFlow(eventId: String): Flow<Event?> {
        return supabase.realtime
            .channel("event_$eventId")
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "events"
                filter = "id=eq.$eventId"
            }
            .map {
                getEvent(eventId)
            }
            .onStart {
                emit(getEvent(eventId))
            }
    }
}

enum class SearchSortOption {
    DATE,
    PRICE,
    NEARBY
}