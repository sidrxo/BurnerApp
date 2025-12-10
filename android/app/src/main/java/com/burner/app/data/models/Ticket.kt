package com.burner.app.data.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.PropertyName
import java.util.Date

/**
 * Ticket model matching iOS Ticket struct
 */
data class Ticket(
    @DocumentId
    val id: String? = null,
    @PropertyName("eventId")
    val eventId: String = "",
    @PropertyName("userId")
    val userId: String = "",
    @PropertyName("ticketNumber")
    val ticketNumber: String? = null,
    @PropertyName("eventName")
    val eventName: String = "",
    val venue: String = "",
    @PropertyName("startTime")
    val startTime: Timestamp? = null,
    @PropertyName("totalPrice")
    val totalPrice: Double = 0.0,
    @PropertyName("purchaseDate")
    val purchaseDate: Timestamp? = null,
    val status: String = TicketStatus.CONFIRMED,
    @PropertyName("qrCode")
    val qrCode: String? = null,
    @PropertyName("venueId")
    val venueId: String? = null,
    @PropertyName("usedAt")
    val usedAt: Timestamp? = null,
    @PropertyName("scannedBy")
    val scannedBy: String? = null,
    @PropertyName("cancelledAt")
    val cancelledAt: Timestamp? = null,
    @PropertyName("refundedAt")
    val refundedAt: Timestamp? = null,
    @PropertyName("transferredFrom")
    val transferredFrom: String? = null,
    @PropertyName("transferredAt")
    val transferredAt: Timestamp? = null,
    @PropertyName("updatedAt")
    val updatedAt: Timestamp? = null,
    @PropertyName("eventImageUrl")
    val eventImageUrl: String? = null
) {
    val startDate: Date?
        get() = startTime?.toDate()

    val purchaseDateValue: Date?
        get() = purchaseDate?.toDate()

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
