package com.burner.app.data.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.GeoPoint
import com.google.firebase.firestore.PropertyName
import java.util.Calendar
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
    @PropertyName("featuredPriority")
    val featuredPriority: Int? = null,
    val description: String? = null,
    val status: String? = null,
    val tags: List<String>? = null,
    @PropertyName("createdAt")
    val createdAt: Timestamp? = null,
    @PropertyName("updatedAt")
    val updatedAt: Timestamp? = null
) {
    @get:Exclude
    var coordinates: GeoPoint? = null

    @set:PropertyName("coordinates")
    var coordinatesMap: HashMap<String, Any>? = null
        set(value) {
            field = value
            if (value != null) {
                val lat = value["latitude"] as? Double
                val lon = value["longitude"] as? Double
                if (lat != null && lon != null) {
                    coordinates = GeoPoint(lat, lon)
                }
            }
        }

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

    val isPast: Boolean
        get() {
            val localStartTime = startDate ?: return true
            val calendar = Calendar.getInstance()
            calendar.time = localStartTime

            // Find the start of the next day
            calendar.add(Calendar.DAY_OF_MONTH, 1)
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)

            // Add 6 hours to get 6 AM on the next day
            calendar.add(Calendar.HOUR_OF_DAY, 6)

            val nextDay6AM = calendar.time
            return Date() > nextDay6AM
        }

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
