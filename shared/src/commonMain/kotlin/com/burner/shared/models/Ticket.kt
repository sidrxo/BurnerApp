package com.burner.shared.models

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Ticket model
 * Based on iOS Ticket struct
 */
@Serializable
data class Ticket(
    // Primary identifier
    @SerialName("ticket_id")
    val ticketId: String? = null,

    // Identity
    @SerialName("event_id")
    val eventId: String = "",

    @SerialName("user_id")
    val userId: String = "",

    @SerialName("ticket_number")
    val ticketNumber: String? = null,

    // Event info (fallback data)
    @SerialName("event_name")
    val eventName: String = "",

    val venue: String = "",

    @SerialName("start_time")
    val startTime: String? = null,

    // Purchase info
    @SerialName("total_price")
    val totalPrice: Double? = null,

    @SerialName("purchase_date")
    val purchaseDate: String? = null,

    // Status & QR
    val status: String = TicketStatus.CONFIRMED,

    @SerialName("qr_code")
    val qrCode: String? = null,

    // Optional metadata
    @SerialName("venue_id")
    val venueId: String? = null,

    @SerialName("payment_intent_id")
    val paymentIntentId: String? = null,

    @SerialName("used_at")
    val usedAt: String? = null,

    @SerialName("scanned_by")
    val scannedBy: String? = null,

    @SerialName("cancelled_at")
    val cancelledAt: String? = null,

    @SerialName("cancel_reason")
    val cancelReason: String? = null,

    @SerialName("refunded_at")
    val refundedAt: String? = null,

    @SerialName("refund_amount")
    val refundAmount: Double? = null,

    @SerialName("transferred_from")
    val transferredFrom: String? = null,

    @SerialName("transferred_at")
    val transferredAt: String? = null,

    @SerialName("deleted_at")
    val deletedAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null
) {
    /**
     * Computed property for ID (matches iOS Identifiable conformance)
     */
    val id: String? get() = ticketId

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
     * Parse purchase date to Instant
     */
    val purchaseInstant: Instant?
        get() = purchaseDate?.let {
            try {
                Instant.parse(it)
            } catch (e: Exception) {
                null
            }
        }

    /**
     * Check if ticket is for an upcoming event
     */
    val isUpcoming: Boolean
        get() {
            val start = startInstant ?: return false
            val isValidStatus = status == TicketStatus.CONFIRMED || status == TicketStatus.USED
            return start > Clock.System.now() && isValidStatus
        }

    /**
     * Check if ticket is for a past event
     */
    val isPast: Boolean
        get() {
            val start = startInstant ?: return true
            val isCancelled = status == TicketStatus.CANCELLED || status == TicketStatus.REFUNDED
            return start < Clock.System.now() || isCancelled
        }

    /**
     * Check if ticket is active (confirmed or used)
     */
    val isActive: Boolean
        get() = status == TicketStatus.CONFIRMED || status == TicketStatus.USED

    companion object {
        fun empty() = Ticket()
    }
}

/**
 * Ticket status constants
 */
object TicketStatus {
    const val CONFIRMED = "confirmed"
    const val CANCELLED = "cancelled"
    const val REFUNDED = "refunded"
    const val USED = "used"
}

/**
 * Combined ticket with full event data
 */
@Serializable
data class TicketWithEventData(
    val ticket: Ticket,
    val event: Event?
) {
    val id: String get() = ticket.ticketId ?: ""
}
