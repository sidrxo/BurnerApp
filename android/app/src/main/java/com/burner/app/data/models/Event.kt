package com.burner.app.data.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.GeoPoint
import com.google.firebase.firestore.PropertyName
import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient
import java.util.Date

/**
 * Event model matching iOS Event struct
 */
data class Event(
    @DocumentId
    val id: String? = null,
    val name: String = "",
    val venue: String = "",
    @PropertyName("venueId")
    val venueId: String? = null,
    @PropertyName("startTime")
    val startTime: Timestamp? = null,
    @PropertyName("endTime")
    val endTime: Timestamp? = null,
    val price: Double = 0.0,
    @PropertyName("maxTickets")
    val maxTickets: Int = 0,
    @PropertyName("ticketsSold")
    val ticketsSold: Int = 0,
    @PropertyName("imageUrl")
    val imageUrl: String = "",
    @PropertyName("isFeatured")
    val isFeatured: Boolean = false,
    val description: String? = null,
    val status: String? = null,
    val tags: List<String>? = null,
    val coordinates: GeoPoint? = null,
    @PropertyName("createdAt")
    val createdAt: Timestamp? = null,
    @PropertyName("updatedAt")
    val updatedAt: Timestamp? = null
) {
    // Computed properties
    val isAvailable: Boolean
        get() = ticketsSold < maxTickets && status != "cancelled"

    val isSoldOut: Boolean
        get() = ticketsSold >= maxTickets

    val ticketsRemaining: Int
        get() = maxOf(0, maxTickets - ticketsSold)

    val startDate: Date?
        get() = startTime?.toDate()

    val endDate: Date?
        get() = endTime?.toDate()

    fun distanceFrom(latitude: Double, longitude: Double): Double? {
        val coords = coordinates ?: return null
        return haversineDistance(
            coords.latitude, coords.longitude,
            latitude, longitude
        )
    }

    private fun haversineDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ): Double {
        val r = 6371.0 // Earth's radius in km
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2)
        val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
        return r * c
    }

    companion object {
        fun empty() = Event()
    }
}
