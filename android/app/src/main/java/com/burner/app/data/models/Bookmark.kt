package com.burner.app.data.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.PropertyName
import java.util.Date

/**
 * Bookmark model matching iOS BookmarkData struct
 */
data class Bookmark(
    @PropertyName("eventId")
    val eventId: String = "",
    @PropertyName("eventName")
    val eventName: String = "",
    @PropertyName("eventVenue")
    val eventVenue: String = "",
    @PropertyName("startTime")
    val startTime: Timestamp? = null,
    @PropertyName("eventPrice")
    val eventPrice: Double = 0.0,
    @PropertyName("eventImageUrl")
    val eventImageUrl: String = "",
    @PropertyName("bookmarkedAt")
    val bookmarkedAt: Timestamp? = null
) {
    val startDate: Date?
        get() = startTime?.toDate()

    val bookmarkedDate: Date?
        get() = bookmarkedAt?.toDate()

    companion object {
        fun fromEvent(event: Event): Bookmark {
            return Bookmark(
                eventId = event.id ?: "",
                eventName = event.name,
                eventVenue = event.venue,
                startTime = event.startTime,
                eventPrice = event.price,
                eventImageUrl = event.imageUrl,
                bookmarkedAt = Timestamp.now()
            )
        }
    }
}
