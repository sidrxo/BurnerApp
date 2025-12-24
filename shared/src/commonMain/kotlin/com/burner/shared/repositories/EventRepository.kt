package com.burner.shared.repositories

import com.burner.shared.models.Event
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.datetime.Clock
import kotlin.time.Duration.Companion.days

class EventRepository(private val client: SupabaseClient) {

    @Throws(Exception::class)
    suspend fun fetchEvents(
        sinceDate: kotlinx.datetime.Instant = Clock.System.now(),
        page: Int? = null,
        pageSize: Int? = null
    ): List<Event> {
        val dateString = sinceDate.toString()

        return client.from("events").select {
            filter {
                gte("start_time", dateString)
            }
            if (page != null && pageSize != null) {
                val lowerBound = (page - 1) * pageSize
                val upperBound = lowerBound + pageSize - 1
                range(lowerBound.toLong(), upperBound.toLong())
            }
        }.decodeList<Event>()
    }

    @Throws(Exception::class)
    suspend fun getAllEvents(): List<Event> {
        val sevenDaysAgo = Clock.System.now() - 7.days
        return client.from("events").select {
            filter {
                gte("start_time", sevenDaysAgo.toString())
            }
            order("start_time", Order.ASCENDING)
        }.decodeList<Event>()
    }

    @Throws(Exception::class)
    suspend fun fetchEvent(eventId: String): Event? {
        return client.from("events").select {
            filter {
                eq("id", eventId)
            }
        }.decodeSingleOrNull<Event>()
    }

    @Throws(Exception::class)
    suspend fun fetchEvents(eventIds: List<String>): List<Event> {
        if (eventIds.isEmpty()) return emptyList()

        return client.from("events").select {
            filter {
                isIn("id", eventIds)
            }
        }.decodeList<Event>()
    }

    // --- Restored Search & Filter Functionality ---

    @Throws(Exception::class)
    suspend fun searchEvents(
        query: String,
        sortBy: SearchSortOption = SearchSortOption.DATE,
        userLatitude: Double? = null,
        userLongitude: Double? = null
    ): List<Event> {
        val now = Clock.System.now().toString()

        // 1. Fetch all future events (filtering logic done in memory for flexibility)
        val events = client.from("events").select {
            filter {
                gt("start_time", now)
            }
            order("start_time", Order.ASCENDING)
            limit(100)
        }.decodeList<Event>()

        // 2. Client-side text search
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

        // 3. Sorting
        return when (sortBy) {
            SearchSortOption.DATE -> filtered.sortedBy { it.startInstant }
            SearchSortOption.PRICE -> filtered.sortedBy { it.price }
            SearchSortOption.NEARBY -> {
                if (userLatitude != null && userLongitude != null) {
                    filtered.sortedBy {
                        it.distanceFrom(userLatitude, userLongitude) ?: Double.MAX_VALUE
                    }
                } else {
                    filtered
                }
            }
        }.take(20)
    }

    @Throws(Exception::class)
    suspend fun getNearbyEvents(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 50.0,
        limit: Int = 10
    ): List<Event> {
        val now = Clock.System.now().toString()

        val events = client.from("events").select {
            filter {
                gt("start_time", now)
            }
            order("start_time", Order.ASCENDING)
            limit(100)
        }.decodeList<Event>()

        return events
            .filter { event ->
                event.distanceFrom(latitude, longitude)?.let { distance ->
                    distance <= radiusKm
                } ?: false
            }
            .sortedBy { it.distanceFrom(latitude, longitude) }
            .take(limit)
    }

    @Throws(Exception::class)
    suspend fun getEventsByGenre(genre: String, limit: Int = 20): List<Event> {
        val now = Clock.System.now().toString()
        return client.from("events").select {
            filter {
                // Assuming 'tags' is a Postgres array or JSONB
                contains("tags", listOf(genre))
                gt("start_time", now)
            }
            order("start_time", Order.ASCENDING)
            limit(limit.toLong())
        }.decodeList<Event>()
    }
}

// --- Enum Definition ---
enum class SearchSortOption {
    DATE,
    PRICE,
    NEARBY
}