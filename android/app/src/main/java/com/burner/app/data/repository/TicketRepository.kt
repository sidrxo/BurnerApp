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
    private val TAG = "TicketRepo"

    // 1. Get user's tickets (List View)
    fun getUserTickets(): Flow<List<Ticket>> {
        val userId = authService.currentUserId
        if (userId == null) {
            return flowOf(emptyList())
        }

        val uniqueChannelId = "tickets_${userId}_${UUID.randomUUID()}"
        Log.d(TAG, "Subscribing to tickets list: $uniqueChannelId")

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

    // 2. Get single ticket (Detail View)
    fun getTicketFlow(ticketId: String): Flow<Ticket?> {
        val userId = authService.currentUserId ?: return flowOf(null)

        val uniqueChannelId = "ticket_detail_${ticketId}_${UUID.randomUUID()}"

        return supabase.realtime.channel(uniqueChannelId)
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "tickets"
                // FIX: Changed 'id' to 'ticket_id' to match your DB schema
                filter = "ticket_id=eq.$ticketId"
            }
            .map {
                getTicket(ticketId)
            }
            .onStart {
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
                    order("purchase_date", Order.DESCENDING)
                }
                .decodeList<Ticket>()
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching tickets list", e)
            emptyList()
        }
    }

    suspend fun getTicket(ticketId: String): Ticket? {
        val userId = authService.currentUserId ?: return null
        return try {
            val result = supabase.postgrest.from("tickets")
                .select(columns = Columns.ALL) {
                    filter {
                        // FIX: Removed 'id' check completely. Only use 'ticket_id'.
                        eq("ticket_id", ticketId)
                        eq("user_id", userId)
                    }
                    limit(1)
                }
                .decodeList<Ticket>()
            result.firstOrNull()
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching single ticket", e)
            null
        }
    }
}