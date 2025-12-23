package com.burner.shared.domain

import com.burner.shared.models.Ticket
import com.burner.shared.models.TicketStatus

/**
 * Use case for tracking ticket status
 * Encapsulates business logic for ticket status operations
 */
class TicketStatusTracker {

    /**
     * Get active (upcoming) tickets from a list
     */
    fun getActiveTickets(tickets: List<Ticket>): List<Ticket> {
        return tickets.filter { it.isUpcoming && it.isActive }
    }

    /**
     * Get past tickets from a list
     */
    fun getPastTickets(tickets: List<Ticket>): List<Ticket> {
        return tickets.filter { it.isPast }
    }

    /**
     * Get tickets for a specific event
     */
    fun getTicketsForEvent(tickets: List<Ticket>, eventId: String): List<Ticket> {
        return tickets.filter { it.eventId == eventId }
    }

    /**
     * Check if user has a confirmed ticket for an event
     */
    fun hasConfirmedTicket(tickets: List<Ticket>, eventId: String): Boolean {
        return tickets.any { ticket ->
            ticket.eventId == eventId && ticket.status == TicketStatus.CONFIRMED
        }
    }

    /**
     * Count tickets by status
     */
    fun countByStatus(tickets: List<Ticket>): Map<String, Int> {
        return tickets.groupingBy { it.status }.eachCount()
    }

    /**
     * Get total spent on tickets
     */
    fun getTotalSpent(tickets: List<Ticket>): Double {
        return tickets
            .filter { it.status != TicketStatus.REFUNDED }
            .sumOf { it.totalPrice ?: 0.0 }
    }

    /**
     * Sort tickets by purchase date (newest first)
     */
    fun sortByPurchaseDate(tickets: List<Ticket>, ascending: Boolean = false): List<Ticket> {
        return if (ascending) {
            tickets.sortedBy { it.purchaseInstant }
        } else {
            tickets.sortedByDescending { it.purchaseInstant }
        }
    }

    /**
     * Sort tickets by event date
     */
    fun sortByEventDate(tickets: List<Ticket>, ascending: Boolean = true): List<Ticket> {
        return if (ascending) {
            tickets.sortedBy { it.startInstant }
        } else {
            tickets.sortedByDescending { it.startInstant }
        }
    }
}
