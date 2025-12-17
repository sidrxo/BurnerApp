package com.burner.app.data.repository

import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.Event
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.datetime.Clock
import android.util.Log
import kotlinx.datetime.Instant
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.time.Duration.Companion.days

@Singleton
class EventRepository @Inject constructor(
    private val supabase: BurnerSupabaseClient
) {
    // Get all events (real-time) - matching iOS which fetches from 7 days ago
    val allEvents: Flow<List<Event>> = flow {
        Log.d("EventRepository", "allEvents Flow: Starting initial fetch")
        // Emit initial events immediately (fixes infinite loading issue)
        val initialEvents = getAllEvents()
        Log.d("EventRepository", "allEvents Flow: Initial fetch returned ${initialEvents.size} events")
        emit(initialEvents)

        // Then listen for realtime updates
        Log.d("EventRepository", "allEvents Flow: Setting up realtime subscription")
        supabase.realtime
            .channel("events")
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "events"
            }
            .collect {
                Log.d("EventRepository", "allEvents Flow: Realtime update received, fetching fresh data")
                emit(getAllEvents())
            }
    }

    // Get all events with filter
    suspend fun getAllEvents(): List<Event> {
        return try {
            Log.d("EventRepository", "getAllEvents: Fetching events from Supabase")
            val sevenDaysAgo = Clock.System.now() - 7.days
            val allEvents = supabase.postgrest.from("events")
                .select(columns = Columns.ALL)
                .decodeList<Event>()

            Log.d("EventRepository", "getAllEvents: Fetched ${allEvents.size} total events from database")

            val filteredEvents = allEvents
                .filter { event ->
                    event.startTime?.let { Instant.parse(it) >= sevenDaysAgo } ?: false
                }
                .sortedBy { it.startTime }

            Log.d("EventRepository", "getAllEvents: After filtering (>= 7 days ago): ${filteredEvents.size} events")
            filteredEvents
        } catch (e: Exception) {
            Log.e("EventRepository", "getAllEvents: Error fetching events", e)
            emptyList()
        }
    }

    // Get featured events
    suspend fun getFeaturedEvents(limit: Int = 5): List<Event> {
        return try {
            val now = Clock.System.now().toString()
            supabase.postgrest.from("events")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("is_featured", true)
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(limit.toLong())
                }
                .decodeList<Event>()
                .shuffled() // Shuffle like iOS does
        } catch (e: Exception) {
            emptyList()
        }
    }

    // Get events this week
    suspend fun getThisWeekEvents(limit: Int = 10): List<Event> {
        val now = Clock.System.now()
        val oneWeekLater = now + 7.days

        return try {
            supabase.postgrest.from("events")
                .select(columns = Columns.ALL) {
                    filter {
                        gt("start_time", now.toString())
                        lt("start_time", oneWeekLater.toString())
                    }
                    order("start_time", Order.ASCENDING)
                    limit(limit.toLong())
                }
                .decodeList<Event>()
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
        return try {
            val now = Clock.System.now().toString()
            val events = supabase.postgrest.from("events")
                .select(columns = Columns.ALL) {
                    filter {
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(100) // Fetch more to filter
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
            emptyList()
        }
    }

    // Get events by genre/tag
    suspend fun getEventsByGenre(genre: String, limit: Int = 20): List<Event> {
        return try {
            val now = Clock.System.now().toString()
            supabase.postgrest.from("events")
                .select(columns = Columns.ALL) {
                    filter {
                        // Supabase array contains filter
                        contains("tags", listOf(genre))
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(limit.toLong())
                }
                .decodeList<Event>()
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
            val now = Clock.System.now().toString()
            val events = supabase.postgrest.from("events")
                .select(columns = Columns.ALL) {
                    filter {
                        gt("start_time", now)
                    }
                    order("start_time", Order.ASCENDING)
                    limit(100)
                }
                .decodeList<Event>()

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
            emptyList()
        }
    }

    // Get single event by ID
    suspend fun getEvent(eventId: String): Event? {
        return try {
            supabase.postgrest.from("events")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("id", eventId)
                    }
                }
                .decodeSingle<Event>()
        } catch (e: Exception) {
            null
        }
    }

    // Get event (real-time)
    fun getEventFlow(eventId: String): Flow<Event?> = flow {
        Log.d("EventRepository", "getEventFlow: Starting initial fetch for event $eventId")
        // Emit initial event immediately (fixes infinite loading issue)
        val initialEvent = getEvent(eventId)
        Log.d("EventRepository", "getEventFlow: Initial fetch returned event: ${initialEvent?.name ?: "null"}")
        emit(initialEvent)

        // Then listen for realtime updates
        Log.d("EventRepository", "getEventFlow: Setting up realtime subscription for event $eventId")
        supabase.realtime
            .channel("event_$eventId")
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "events"
                filter = "id=eq.$eventId"
            }
            .collect {
                Log.d("EventRepository", "getEventFlow: Realtime update received for event $eventId")
                emit(getEvent(eventId))
            }
    }
}

enum class SearchSortOption {
    DATE,
    PRICE,
    NEARBY
}