package com.burner.shared.domain

import com.burner.shared.models.Event
import kotlinx.datetime.Clock
import kotlin.time.Duration.Companion.days

/**
 * Use case for filtering events
 * Encapsulates business logic for event filtering
 */
class EventFilteringUseCase {

    /**
     * Filter events to get featured ones
     */
    fun filterFeatured(events: List<Event>, limit: Int = 5): List<Event> {
        val now = Clock.System.now()
        return events
            .filter { it.isFeatured && (it.startInstant?.let { start -> start > now } ?: false) }
            .sortedBy { it.featuredPriority ?: Int.MAX_VALUE }
            .take(limit)
    }

    /**
     * Filter events happening this week
     */
    fun filterThisWeek(events: List<Event>, limit: Int = 10): List<Event> {
        val now = Clock.System.now()
        val oneWeekLater = now + 7.days

        return events
            .filter { event ->
                event.startInstant?.let { start ->
                    start > now && start < oneWeekLater
                } ?: false
            }
            .sortedBy { it.startInstant }
            .take(limit)
    }

    /**
     * Filter events by proximity to user location
     */
    fun filterNearby(
        events: List<Event>,
        userLatitude: Double,
        userLongitude: Double,
        radiusKm: Double = 50.0,
        limit: Int = 10
    ): List<Event> {
        val now = Clock.System.now()

        return events
            .filter { event ->
                // Must be upcoming
                val isUpcoming = event.startInstant?.let { it > now } ?: false
                if (!isUpcoming) return@filter false

                // Must be within radius
                event.distanceFrom(userLatitude, userLongitude)?.let { distance ->
                    distance <= radiusKm
                } ?: false
            }
            .sortedBy { it.distanceFrom(userLatitude, userLongitude) }
            .take(limit)
    }

    /**
     * Filter events by genre/tag
     */
    fun filterByGenre(events: List<Event>, genre: String): List<Event> {
        val now = Clock.System.now()

        return events
            .filter { event ->
                val isUpcoming = event.startInstant?.let { it > now } ?: false
                val hasGenre = event.tags?.contains(genre) ?: false
                isUpcoming && hasGenre
            }
            .sortedBy { it.startInstant }
    }

    /**
     * Filter events by multiple genres
     */
    fun filterByGenres(events: List<Event>, genres: List<String>): List<Event> {
        if (genres.isEmpty()) return events

        val now = Clock.System.now()

        return events
            .filter { event ->
                val isUpcoming = event.startInstant?.let { it > now } ?: false
                val hasAnyGenre = event.tags?.any { tag -> genres.contains(tag) } ?: false
                isUpcoming && hasAnyGenre
            }
            .sortedBy { it.startInstant }
    }

    /**
     * Filter available events (has tickets remaining)
     */
    fun filterAvailable(events: List<Event>): List<Event> {
        return events.filter { it.isAvailable }
    }

    /**
     * Filter upcoming events (not in the past)
     */
    fun filterUpcoming(events: List<Event>): List<Event> {
        return events.filter { !it.isPast }
    }
}
