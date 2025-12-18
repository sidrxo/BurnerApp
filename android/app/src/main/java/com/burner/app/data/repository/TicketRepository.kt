package com.burner.app.data.repository

import android.util.Log
import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.Ticket
import com.burner.app.services.AuthService
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TicketRepository @Inject constructor(
    private val supabase: BurnerSupabaseClient,
    private val authService: AuthService
) {
    // Get user's tickets (real-time list)
    fun getUserTickets(): Flow<List<Ticket>> {
        val userId = authService.currentUserId
        if (userId == null) {
            return flowOf(emptyList())
        }

        // Unique channel for the list view
        val uniqueChannelId = "tickets_${userId}_${UUID.randomUUID()}"
        Log.d("TicketRepo", "Subscribing to tickets list: $uniqueChannelId")

        return supabase.realtime
            .channel(uniqueChannelId)
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "tickets"
                filter = "user_id=eq.$userId"
            }
            .map {
                getUserTicketsList(userId)
            }
            .onStart {
                emit(getUserTicketsList(userId))
            }
    }

    // ADDED THIS FUNCTION (Fixes 'Unresolved reference: getTicketFlow')
    fun getTicketFlow(ticketId: String): Flow<Ticket?> {
        val userId = authService.currentUserId ?: return flowOf(null)

        // Unique channel for this specific ticket detail view
        val uniqueChannelId = "ticket_detail_${ticketId}_${UUID.randomUUID()}"
        Log.d("TicketRepo", "Subscribing to single ticket: $uniqueChannelId")

        return supabase.realtime.channel(uniqueChannelId)
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "tickets"
                filter = "id=eq.$ticketId"
            }
            .map {
                // When the ticket changes (e.g. status updates), fetch fresh data
                getTicket(ticketId)
            }
            .onStart {
                // Load immediately
                emit(getTicket(ticketId))
            }
    }

    private suspend fun getUserTicketsList(userId: String): List<Ticket> {
        return try {
            supabase.postgrest.from("tickets")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("user_id", userId)
                    }
                    order("created_at", Order.DESCENDING)
                }
                .decodeList<Ticket>()
        } catch (e: Exception) {
            Log.e("TicketRepo", "Error fetching tickets", e)
            emptyList()
        }
    }

    // Single fetch (helper used by getTicketFlow)
    suspend fun getTicket(ticketId: String): Ticket? {
        val userId = authService.currentUserId ?: return null
        return try {
            val result = supabase.postgrest.from("tickets")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("id", ticketId)
                        eq("user_id", userId)
                    }
                    limit(1)
                }
                .decodeList<Ticket>()
            result.firstOrNull()
        } catch (e: Exception) {
            Log.e("TicketRepo", "Error fetching ticket details", e)
            null
        }
    }
}