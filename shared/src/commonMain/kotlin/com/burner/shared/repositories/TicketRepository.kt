package com.burner.shared.repositories

import com.burner.shared.models.Ticket

/**
 * Ticket Repository
 * Handles all ticket-related data operations
 * Based on iOS TicketRepository implementation
 */
class TicketRepository(private val supabaseClient: SupabaseClient) {

    /**
     * Fetch all tickets for a user
     */
    suspend fun fetchUserTickets(userId: String): Result<List<Ticket>> {
        return try {
            val tickets = supabaseClient.from("tickets")
                .select()
                .eq("user_id", userId.lowercase())
                .order("purchase_date", ascending = false)
                .execute<List<Ticket>>()

            Result.success(tickets)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Check if user has a ticket for a specific event
     */
    suspend fun userHasTicket(userId: String, eventId: String): Result<Boolean> {
        return try {
            val tickets = supabaseClient.from("tickets")
                .select()
                .eq("user_id", userId)
                .eq("event_id", eventId)
                .eq("status", "confirmed")
                .execute<List<Ticket>>()

            Result.success(tickets.isNotEmpty())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Fetch user ticket status for multiple events
     * Returns a map of eventId to hasTicket boolean
     */
    suspend fun fetchUserTicketStatus(
        userId: String,
        eventIds: List<String>
    ): Result<Map<String, Boolean>> {
        if (eventIds.isEmpty()) return Result.success(emptyMap())

        return try {
            val status = eventIds.associateWith { false }.toMutableMap()

            val tickets = supabaseClient.from("tickets")
                .select()
                .eq("user_id", userId)
                .`in`("event_id", eventIds)
                .eq("status", "confirmed")
                .execute<List<Ticket>>()

            tickets.forEach { ticket ->
                status[ticket.eventId] = true
            }

            Result.success(status)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
