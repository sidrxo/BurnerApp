package com.burner.shared.repositories

import com.burner.shared.models.Ticket
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order

/**
 * Ticket Repository
 * Handles ticket fetching and purchases
 */
class TicketRepository(private val client: SupabaseClient) {

    /**
     * Fetch tickets purchased by user
     */
    suspend fun fetchUserTickets(userId: String): Result<List<Ticket>> {
        return try {
            val tickets = client.from("tickets").select {
                filter {
                    eq("user_id", userId)
                }
                order("created_at", Order.DESCENDING)
            }.decodeList<Ticket>()

            Result.success(tickets)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Fetch ticket by ID
     */
    suspend fun fetchTicket(ticketId: String): Result<Ticket?> {
        return try {
            val ticket = client.from("tickets").select {
                filter {
                    eq("id", ticketId)
                }
            }.decodeSingleOrNull<Ticket>()

            Result.success(ticket)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Purchase a ticket (Placeholder for actual payment logic)
     */
    suspend fun purchaseTicket(
        userId: String,
        eventId: String,
        ticketType: String,
        price: Double
    ): Result<Ticket> {
        return try {
            // In a real app, this would be a server-side function call
            // after payment verification.
            // For now, we simulate inserting a ticket.
            val ticketData = mapOf(
                "user_id" to userId,
                "event_id" to eventId,
                "ticket_type" to ticketType,
                "status" to "active",
                "price" to price
            )

            val ticket = client.from("tickets")
                .insert(ticketData) { select() }
                .decodeSingle<Ticket>()

            Result.success(ticket)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Transfer a ticket to another user
     */
    suspend fun transferTicket(ticketId: String, toEmail: String): Result<Unit> {
        return try {
            // Note: In production, use an Edge Function for this to verify
            // the email exists and handle the transaction securely.
            // This is a client-side approximation.

            client.from("tickets").update(mapOf("status" to "transferred")) {
                filter {
                    eq("id", ticketId)
                }
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}