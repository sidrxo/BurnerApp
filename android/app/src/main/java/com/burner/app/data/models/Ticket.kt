package com.burner.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.datetime.Instant
import java.util.Date

/**
 * Ticket model fully aligned with iOS Ticket struct and Supabase Schema
 */
@Serializable
data class Ticket(
    // Primary identifier - matches iOS 'ticketId' mapping to 'ticket_id'
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

    // Kept as String for custom parsing of Postgres dates
    @SerialName("start_time")
    val startTime: String? = null,

    // Purchase info
    @SerialName("total_price")
    val totalPrice: Double? = null, // Changed to nullable Double to match iOS

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
    val updatedAt: String? = null,

    // Extra field needed for UI logic (not in iOS struct but needed for Android list composition)
    @SerialName("event_image_url")
    val eventImageUrl: String? = null
) {
    // Computed property for Identifiable conformance (matches iOS logic)
    val id: String? get() = ticketId

    // Date Helper: Handles Postgres format "2025-12-15 20:00:00+00"
    val startDate: Date?
        get() = startTime?.let {
            try {
                val isoString = it.trim().replace(" ", "T")
                Date(Instant.parse(isoString).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

    val purchaseDateValue: Date?
        get() = purchaseDate?.let {
            try {
                val isoString = it.trim().replace(" ", "T")
                Date(Instant.parse(isoString).toEpochMilliseconds())
            } catch (e: Exception) {
                null
            }
        }

    // Status Logic
    val isUpcoming: Boolean
        get() {
            val start = startDate ?: return false
            // Matches iOS: Active if Confirmed OR Used (but date hasn't passed)
            val isValidStatus = status == TicketStatus.CONFIRMED || status == TicketStatus.USED
            return start.after(Date()) && isValidStatus
        }

    val isPast: Boolean
        get() {
            val start = startDate ?: return true
            val isCancelled = status == TicketStatus.CANCELLED || status == TicketStatus.REFUNDED
            return start.before(Date()) || isCancelled
        }

    val isActive: Boolean
        get() = status == TicketStatus.CONFIRMED || status == TicketStatus.USED

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