package com.burner.shared.models

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Bookmark model
 * Based on iOS BookmarkData struct
 */
@Serializable
data class Bookmark(
    val id: String? = null,
    @SerialName("event_id")
    val eventId: String = "",
    @SerialName("event_name")
    val eventName: String = "",
    val venue: String = "",
    @SerialName("start_time")
    val startTime: String? = null,
    @SerialName("event_price")
    val eventPrice: Double = 0.0,
    @SerialName("event_image_url")
    val eventImageUrl: String = "",
    @SerialName("bookmarked_at")
    val bookmarkedAt: String? = null
) {
    /**
     * Parse start time to Instant
     */
    val startInstant: Instant?
        get() = startTime?.let {
            try {
                Instant.parse(it)
            } catch (e: Exception) {
                null
            }
        }

    /**
     * Parse bookmarked time to Instant
     */
    val bookmarkedInstant: Instant?
        get() = bookmarkedAt?.let {
            try {
                Instant.parse(it)
            } catch (e: Exception) {
                null
            }
        }

    companion object {
        /**
         * Create a bookmark from an event
         */
        fun fromEvent(event: Event): Bookmark {
            return Bookmark(
                eventId = event.id ?: "",
                eventName = event.name,
                venue = event.venue,
                startTime = event.startTime,
                eventPrice = event.price,
                eventImageUrl = event.imageUrl,
                bookmarkedAt = Clock.System.now().toString()
            )
        }
    }
}
