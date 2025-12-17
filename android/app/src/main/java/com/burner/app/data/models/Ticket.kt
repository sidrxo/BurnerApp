package com.burner.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.datetime.Instant
import java.util.Date

/**
 * Ticket model matching iOS Ticket struct
 * Updated for Supabase
 */
@Serializable
data class Ticket(
    val id: String? = null,
    @SerialName("event_id")
    val eventId: String = "",
    @SerialName("user_id")
    val userId: String = "",
    @SerialName("ticket_number")
    val ticketNumber: String? = null,
    @SerialName("event_name")
    val eventName: String = "",
    val venue: String = "",
    @SerialName("start_time")
    val startTime: String? = null,
    @SerialName("total_price")
    val totalPrice: Double = 0.0,
    @SerialName("purchase_date")
    val purchaseDate: String? = null,
    val status: String = TicketStatus.CONFIRMED,
    @SerialName("qr_code")
    val qrCode: String? = null,
    @SerialName("venue_id")
    val venueId: String? = null,
    @SerialName("used_at")
    val usedAt: String? = null,
    @SerialName("scanned_by")
    val scannedBy: String? = null,
    @SerialName("cancelled_at")
    val cancelledAt: String? = null,
    @SerialName("refunded_at")
    val refundedAt: String? = null,
    @SerialName("transferred_from")
    val transferredFrom: String? = null,
    @SerialName("transferred_at")
    val transferredAt: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null,
    @SerialName("event_image_url")
    val eventImageUrl: String? = null
) {
    val startDate: Date?
        get() = startTime?.let {
            try {
                Date(Instant.parse(it).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

    val purchaseDateValue: Date?
        get() = purchaseDate?.let {
            try {
                Date(Instant.parse(it).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

    val isUpcoming: Boolean
        get() {
            val start = startDate ?: return false
            return start.after(Date()) && status == TicketStatus.CONFIRMED
        }

    val isPast: Boolean
        get() {
            val start = startDate ?: return true
            return start.before(Date()) || status != TicketStatus.CONFIRMED
        }

    val isActive: Boolean
        get() = status == TicketStatus.CONFIRMED

    companion object {
        fun empty() = Ticket()
    }
}

object TicketStatus {
    const val CONFIRMED = "confirmed"
    const val CANCELLED = "cancelled"
    const val REFUNDED = "refunded"
    const val USED = "used"
}

/**
 * Combined ticket with full event data
 */
data class TicketWithEventData(
    val ticket: Ticket,
    val event: Event?
)
