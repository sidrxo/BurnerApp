package com.burner.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.datetime.Instant
import java.util.Date

/**
 * Bookmark model matching iOS BookmarkData struct
 * Updated for Supabase
 */
@Serializable
data class Bookmark(
    @SerialName("event_id")
    val eventId: String = "",
    @SerialName("event_name")
    val eventName: String = "",
    @SerialName("venue")
    val eventVenue: String = "",
    @SerialName("start_time")
    val startTime: String? = null,
    @SerialName("event_price")
    val eventPrice: Double = 0.0,
    @SerialName("event_image_url")
    val eventImageUrl: String = "",
    @SerialName("bookmarked_at")
    val bookmarkedAt: String? = null
) {
    val startDate: Date?
        get() = startTime?.let {
            try {
                Date(Instant.parse(it).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

    val bookmarkedDate: Date?
        get() = bookmarkedAt?.let {
            try {
                Date(Instant.parse(it).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

    companion object {
        fun fromEvent(event: Event): Bookmark {
            return Bookmark(
                eventId = event.id ?: "",
                eventName = event.name,
                eventVenue = event.venue,
                startTime = event.startTime,
                eventPrice = event.price,
                eventImageUrl = event.imageUrl,
                bookmarkedAt = Instant.fromEpochMilliseconds(System.currentTimeMillis()).toString()
            )
        }
    }
}
