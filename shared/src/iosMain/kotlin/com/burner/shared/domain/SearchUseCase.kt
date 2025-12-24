package com.burner.shared.domain

import com.burner.shared.models.Event
import com.burner.shared.repositories.SearchSortOption

/**
 * Use case for searching and sorting events
 * Encapsulates business logic for search operations
 */
class SearchUseCase {

    /**
     * Search events by query string
     */
    fun searchEvents(
        events: List<Event>,
        query: String
    ): List<Event> {
        if (query.isBlank()) return events

        val lowercaseQuery = query.lowercase()

        return events.filter { event ->
            event.name.lowercase().contains(lowercaseQuery) ||
            event.venue.lowercase().contains(lowercaseQuery) ||
            event.description?.lowercase()?.contains(lowercaseQuery) == true ||
            event.tags?.any { it.lowercase().contains(lowercaseQuery) } == true
        }
    }

    /**
     * Sort events by specified criteria
     */
    fun sortEvents(
        events: List<Event>,
        sortBy: SearchSortOption,
        userLatitude: Double? = null,
        userLongitude: Double? = null
    ): List<Event> {
        return when (sortBy) {
            SearchSortOption.DATE -> events.sortedBy { it.startInstant }
            SearchSortOption.PRICE -> events.sortedBy { it.price }
            SearchSortOption.NEARBY -> {
                if (userLatitude != null && userLongitude != null) {
                    events.sortedBy {
                        it.distanceFrom(userLatitude, userLongitude) ?: Double.MAX_VALUE
                    }
                } else {
                    events
                }
            }
        }
    }

    /**
     * Search and sort events in one operation
     */
    fun searchAndSort(
        events: List<Event>,
        query: String,
        sortBy: SearchSortOption,
        userLatitude: Double? = null,
        userLongitude: Double? = null,
        limit: Int = 10
    ): List<Event> {
        val searchResults = searchEvents(events, query)
        val sorted = sortEvents(searchResults, sortBy, userLatitude, userLongitude)
        return sorted.take(limit)
    }
}
