package com.burner.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.util.Calendar
import java.util.Date

/**
 * Event model matching iOS Event struct
 * Updated for Supabase
 */
@Serializable
data class Event(
    val id: String? = null,
    val name: String = "",
    val venue: String = "",
    @SerialName("venue_id")
    val venueId: String? = null,
    @SerialName("start_time")
    val startTime: String? = null,
    @SerialName("end_time")
    val endTime: String? = null,
    val price: Double = 0.0,
    @SerialName("max_tickets")
    val maxTickets: Int = 0,
    @SerialName("tickets_sold")
    val ticketsSold: Int = 0,
    @SerialName("image_url")
    val imageUrl: String = "",
    @SerialName("is_featured")
    val isFeatured: Boolean = false,
    val description: String? = null,
    val status: String? = null,
    val tags: List<String>? = null,
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null
) {
    // Computed properties
    val isAvailable: Boolean
        get() = ticketsSold < maxTickets && status != "cancelled"

    val isSoldOut: Boolean
        get() = ticketsSold >= maxTickets

    val ticketsRemaining: Int
        get() = maxOf(0, maxTickets - ticketsSold)

    val startDate: Date?
        get() = startTime?.let {
            try {
                Date(Instant.parse(it).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

    val endDate: Date?
        get() = endTime?.let {
            try {
                Date(Instant.parse(it).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

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

    fun distanceFrom(userLatitude: Double, userLongitude: Double): Double? {
        val lat = latitude ?: return null
        val lon = longitude ?: return null
        return haversineDistance(lat, lon, userLatitude, userLongitude)
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
