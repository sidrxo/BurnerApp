package com.burner.shared.repositories

import com.burner.shared.models.Event
import kotlinx.datetime.Clock
import kotlin.time.Duration.Companion.days

/**
 * Event Repository
 * Handles all event-related data operations
 * Based on iOS EventRepository implementation
 */
class EventRepository(private val supabaseClient: SupabaseClient) {

    /**
     * Fetch events from server since a specific date
     * @param sinceDate Events starting after this timestamp
     * @param page Optional page number for pagination
     * @param pageSize Optional page size for pagination
     * @return List of events
     */
    suspend fun fetchEvents(
        sinceDate: kotlinx.datetime.Instant = Clock.System.now(),
        page: Int? = null,
        pageSize: Int? = null
    ): Result<List<Event>> {
        return try {
            val dateString = sinceDate.toString()

            // Build query
            var query = supabaseClient.from("events")
                .select()
                .gte("start_time", dateString)

            // Apply pagination if provided
            if (page != null && pageSize != null) {
                val lowerBound = (page - 1) * pageSize
                val upperBound = lowerBound + pageSize - 1
                query = query.range(lowerBound, upperBound)
            }

            val events = query.execute<List<Event>>()
            Result.success(events)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Fetch all events (from last 7 days onwards)
     * Based on Android implementation
     */
    suspend fun getAllEvents(): Result<List<Event>> {
        return try {
            val sevenDaysAgo = Clock.System.now() - 7.days
            val events = supabaseClient.from("events")
                .select()
                .execute<List<Event>>()
                .filter { event ->
                    event.startInstant?.let { it >= sevenDaysAgo } ?: false
                }
                .sortedBy { it.startTime }

            Result.success(events)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Fetch a single event by ID
     */
    suspend fun fetchEvent(eventId: String): Result<Event?> {
        return try {
            val event = supabaseClient.from("events")
                .select()
                .eq("id", eventId)
                .executeSingle<Event>()

            Result.success(event)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Fetch multiple events by IDs
     */
    suspend fun fetchEvents(eventIds: List<String>): Result<List<Event>> {
        if (eventIds.isEmpty()) return Result.success(emptyList())

        return try {
            val events = supabaseClient.from("events")
                .select()
                .`in`("id", eventIds)
                .execute<List<Event>>()

            Result.success(events)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get featured events
     */
    suspend fun getFeaturedEvents(limit: Int = 5): Result<List<Event>> {
        return try {
            val now = Clock.System.now().toString()
            val events = supabaseClient.from("events")
                .select()
                .eq("is_featured", true)
                .gt("start_time", now)
                .order("start_time", ascending = true)
                .limit(limit)
                .execute<List<Event>>()
                .shuffled()

            Result.success(events)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get events happening this week
     */
    suspend fun getThisWeekEvents(limit: Int = 10): Result<List<Event>> {
        return try {
            val now = Clock.System.now()
            val oneWeekLater = now + 7.days

            val events = supabaseClient.from("events")
                .select()
                .gt("start_time", now.toString())
                .lt("start_time", oneWeekLater.toString())
                .order("start_time", ascending = true)
                .limit(limit)
                .execute<List<Event>>()

            Result.success(events)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get nearby events based on user location
     */
    suspend fun getNearbyEvents(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 50.0,
        limit: Int = 10
    ): Result<List<Event>> {
        return try {
            val now = Clock.System.now().toString()
            val events = supabaseClient.from("events")
                .select()
                .gt("start_time", now)
                .order("start_time", ascending = true)
                .limit(100)
                .execute<List<Event>>()

            val nearbyEvents = events
                .filter { event ->
                    event.distanceFrom(latitude, longitude)?.let { distance ->
                        distance <= radiusKm
                    } ?: false
                }
                .sortedBy { it.distanceFrom(latitude, longitude) }
                .take(limit)

            Result.success(nearbyEvents)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get events by genre/tag
     */
    suspend fun getEventsByGenre(genre: String, limit: Int = 20): Result<List<Event>> {
        return try {
            val now = Clock.System.now().toString()
            val events = supabaseClient.from("events")
                .select()
                .contains("tags", listOf(genre))
                .gt("start_time", now)
                .order("start_time", ascending = true)
                .limit(limit)
                .execute<List<Event>>()

            Result.success(events)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Search events by query string
     */
    suspend fun searchEvents(
        query: String,
        sortBy: SearchSortOption = SearchSortOption.DATE,
        userLatitude: Double? = null,
        userLongitude: Double? = null
    ): Result<List<Event>> {
        return try {
            val now = Clock.System.now().toString()
            val events = supabaseClient.from("events")
                .select()
                .gt("start_time", now)
                .order("start_time", ascending = true)
                .limit(100)
                .execute<List<Event>>()

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

            val sorted = when (sortBy) {
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
            }.take(10)

            Result.success(sorted)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

/**
 * Search sort options
 */
enum class SearchSortOption {
    DATE,
    PRICE,
    NEARBY
}

/**
 * Placeholder for Supabase client - will be implemented with platform-specific code
 */
expect class SupabaseClient {
    fun from(table: String): QueryBuilder
}

expect class QueryBuilder {
    fun select(): QueryBuilder
    fun eq(column: String, value: Any): QueryBuilder
    fun gt(column: String, value: Any): QueryBuilder
    fun lt(column: String, value: Any): QueryBuilder
    fun gte(column: String, value: Any): QueryBuilder
    fun `in`(column: String, values: List<String>): QueryBuilder
    fun contains(column: String, values: List<String>): QueryBuilder
    fun order(column: String, ascending: Boolean): QueryBuilder
    fun limit(count: Int): QueryBuilder
    fun range(from: Int, to: Int): QueryBuilder
    suspend fun <T> execute(): T
    suspend fun <T> executeSingle(): T?
}
