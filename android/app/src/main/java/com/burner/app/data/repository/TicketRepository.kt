package com.burner.app.data.repository

import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.burner.app.data.models.Ticket
import com.burner.app.data.models.TicketStatus
import com.burner.app.data.models.TicketWithEventData
import com.burner.app.services.AuthService
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.tasks.await
import java.util.Date
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TicketRepository @Inject constructor(
    private val firestore: FirebaseFirestore,
    private val authService: AuthService,
    private val eventRepository: EventRepository
) {
    private val ticketsCollection = firestore.collection("tickets")

    // Get user's tickets (real-time)
    fun getUserTickets(): Flow<List<Ticket>> = callbackFlow {
        val userId = authService.currentUserId
        if (userId == null) {
            trySend(emptyList())
            close()
            return@callbackFlow
        }

        val listener = ticketsCollection
            .whereEqualTo("userId", userId)
            .orderBy("startTime", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    trySend(emptyList())
                    return@addSnapshotListener
                }

                val tickets = snapshot?.documents?.mapNotNull { doc ->
                    doc.toObject(Ticket::class.java)
                } ?: emptyList()

                trySend(tickets)
            }

        awaitClose { listener.remove() }
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
            ticketsCollection
                .document(ticketId)
                .get()
                .await()
                .toObject(Ticket::class.java)
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
    fun getTicketFlow(ticketId: String): Flow<Ticket?> = callbackFlow {
        val listener = ticketsCollection
            .document(ticketId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    trySend(null)
                    return@addSnapshotListener
                }
                trySend(snapshot?.toObject(Ticket::class.java))
            }

        awaitClose { listener.remove() }
    }

    // Create ticket after successful payment
    suspend fun createTicket(
        eventId: String,
        eventName: String,
        venue: String,
        venueId: String?,
        startTime: Timestamp,
        totalPrice: Double
    ): Result<String> {
        val userId = authService.currentUserId
            ?: return Result.failure(Exception("User not authenticated"))

        return try {
            val ticketId = UUID.randomUUID().toString()
            val ticketNumber = generateTicketNumber()
            val qrCode = generateQRCodeData(ticketId, eventId, userId)

            val ticket = Ticket(
                id = ticketId,
                eventId = eventId,
                userId = userId,
                ticketNumber = ticketNumber,
                eventName = eventName,
                venue = venue,
                venueId = venueId,
                startTime = startTime,
                totalPrice = totalPrice,
                purchaseDate = Timestamp.now(),
                status = TicketStatus.CONFIRMED,
                qrCode = qrCode
            )

            ticketsCollection
                .document(ticketId)
                .set(ticket)
                .await()

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
            ticketsCollection
                .document(ticketId)
                .update(
                    mapOf(
                        "status" to TicketStatus.CANCELLED,
                        "cancelledAt" to Timestamp.now(),
                        "updatedAt" to Timestamp.now()
                    )
                )
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
