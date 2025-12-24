package com.burner.shared.models

import com.burner.shared.utils.haversineDistance
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.math.max
// KMP Specific Imports
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.LocalTime
import kotlinx.datetime.plus
import kotlinx.datetime.toInstant

/**
 * Event model
 * Based on iOS Event struct with computed properties
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
    @SerialName("featured_priority")
    val featuredPriority: Int? = null,
    val description: String? = null,
    val status: String? = null,
    val tags: List<String>? = null,
    val coordinates: Coordinate? = null,
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    /**
     * Check if tickets are available for purchase
     */
    val isAvailable: Boolean
        get() = ticketsSold < maxTickets && status != "cancelled"

    /**
     * Check if the event is sold out
     */
    val isSoldOut: Boolean
        get() = ticketsSold >= maxTickets

    /**
     * Calculate remaining tickets
     */
    val ticketsRemaining: Int
        get() = max(0, maxTickets - ticketsSold)

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
     * Parse end time to Instant
     */
    val endInstant: Instant?
        get() = endTime?.let {
            try {
                Instant.parse(it)
            } catch (e: Exception) {
                null
            }
        }

    /**
     * Check if the event is in the past
     * An event is past if current time is after 6 AM the day after the event
     * Fixed for KMP using DateTimeUnit and LocalTime
     */
    val isPast: Boolean
        get() {
            val start = startInstant ?: return true
            val timeZone = TimeZone.currentSystemDefault()
            val localStart = start.toLocalDateTime(timeZone)

            // 1. Safely add 1 day to the date
            val nextDayDate = localStart.date.plus(1, DateTimeUnit.DAY)

            // 2. Create LocalDateTime for 6:00 AM on that next day
            val nextDay6AM = LocalDateTime(nextDayDate, LocalTime(6, 0))

            // 3. Convert back to Instant to compare with "Now"
            val nextDay6AMInstant = nextDay6AM.toInstant(timeZone)

            return Clock.System.now() > nextDay6AMInstant
        }

    /**
     * Check if the event has started
     */
    val hasStarted: Boolean
        get() {
            val start = startInstant ?: return false
            return Clock.System.now() >= start
        }

    /**
     * Calculate distance from a given location
     * @param userLatitude User's latitude
     * @param userLongitude User's longitude
     * @return Distance in kilometers, or null if coordinates not available
     */
    fun distanceFrom(userLatitude: Double, userLongitude: Double): Double? {
        val coord = coordinates ?: return null
        return haversineDistance(
            coord.latitude,
            coord.longitude,
            userLatitude,
            userLongitude
        )
    }

    companion object {
        fun empty() = Event()
    }
}