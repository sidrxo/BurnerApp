package com.burner.app.data.repository

import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.Ticket
import com.burner.app.data.models.TicketStatus
import com.burner.app.data.models.TicketWithEventData
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
import kotlinx.datetime.Clock
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TicketRepository @Inject constructor(
    private val supabase: BurnerSupabaseClient,
    private val authService: AuthService,
    private val eventRepository: EventRepository
) {
    // Get user's tickets (real-time)
    fun getUserTickets(): Flow<List<Ticket>> {
        val userId = authService.currentUserId
        if (userId == null) {
            return flowOf(emptyList())
        }

        return supabase.realtime
            .channel("tickets_$userId")
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "tickets"
                filter = "user_id=eq.$userId"
            }
            .map {
                getUserTicketsList(userId)
            }
            .onStart { // <--- ADD THIS BLOCK
                emit(getUserTicketsList(userId))
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
            emptyList()
        }
    }

    // Get upcoming tickets
    fun getUpcomingTickets(): Flow<List<Ticket>> = getUserTickets().map { tickets ->
        tickets.filter { it.isUpcoming }
    }

    // Get past tickets
    fun getPastTickets(): Flow<List<Ticket>> = getUserTickets().map { tickets ->
        tickets.filter { it.isPast }
    }

    // Get single ticket by ID
    suspend fun getTicket(ticketId: String): Ticket? {
        return try {
            supabase.postgrest.from("tickets")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("id", ticketId)
                    }
                }
                .decodeSingle<Ticket>()
        } catch (e: Exception) {
            null
        }
    }

    // Get ticket with event data
    suspend fun getTicketWithEventData(ticketId: String): TicketWithEventData? {
        val ticket = getTicket(ticketId) ?: return null
        val event = eventRepository.getEvent(ticket.eventId)
        return TicketWithEventData(ticket, event)
    }

    // Get ticket (real-time)
    fun getTicketFlow(ticketId: String): Flow<Ticket?> {
        return supabase.realtime
            .channel("ticket_$ticketId")
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "tickets"
                filter = "id=eq.$ticketId"
            }
            .map {
                getTicket(ticketId)
            }
    }

    // Create ticket after successful payment
    suspend fun createTicket(
        eventId: String,
        eventName: String,
        venue: String,
        venueId: String?,
        startTime: String,
        totalPrice: Double,
        eventImageUrl: String? = null
    ): Result<String> {
        val userId = authService.currentUserId
            ?: return Result.failure(Exception("User not authenticated"))

        return try {
            val ticketId = UUID.randomUUID().toString()
            val ticketNumber = generateTicketNumber()
            val qrCode = generateQRCodeData(ticketId, eventId, userId)
            val now = Clock.System.now().toString()

            val ticketData = mapOf(
                "id" to ticketId,
                "event_id" to eventId,
                "user_id" to userId,
                "ticket_number" to ticketNumber,
                "event_name" to eventName,
                "venue" to venue,
                "venue_id" to venueId,
                "start_time" to startTime,
                "total_price" to totalPrice,
                "purchase_date" to now,
                "status" to TicketStatus.CONFIRMED, // Fixed: Removed .name
                "qr_code" to qrCode,
                "event_image_url" to eventImageUrl
            )

            supabase.postgrest.from("tickets")
                .insert(ticketData)

            Result.success(ticketId)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Generate ticket number (format: BRN-XXXXX)
    private fun generateTicketNumber(): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        val code = (1..5).map { chars.random() }.joinToString("")
        return "BRN-$code"
    }

    // Generate QR code data
    private fun generateQRCodeData(ticketId: String, eventId: String, userId: String): String {
        return "burner://ticket/$ticketId?event=$eventId&user=$userId"
    }

    // Cancel ticket
    suspend fun cancelTicket(ticketId: String): Result<Unit> {
        return try {
            val now = Clock.System.now().toString()
            val updateData = mapOf(
                "status" to TicketStatus.CANCELLED, // Fixed: Removed .name
                "cancelled_at" to now,
                "updated_at" to now
            )

            supabase.postgrest.from("tickets")
                .update(updateData) {
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