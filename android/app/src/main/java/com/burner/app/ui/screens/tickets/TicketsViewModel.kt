package com.burner.app.ui.screens.tickets

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.models.Ticket
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.TicketRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TicketsUiState(
    val upcomingTickets: List<Ticket> = emptyList(),
    val pastTickets: List<Ticket> = emptyList(),
    val isLoading: Boolean = true,
    val isAuthenticated: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class TicketsViewModel @Inject constructor(
    private val ticketRepository: TicketRepository,
    private val eventRepository: EventRepository,
    private val authService: AuthService
) : ViewModel() {

    private val TAG = "TicketsViewModel"
    private val _uiState = MutableStateFlow(TicketsUiState())
    val uiState: StateFlow<TicketsUiState> = _uiState.asStateFlow()

    private var eventsCache: Map<String, Event> = emptyMap()

    init {
        observeAuthState()
        observeEvents()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authService.authStateFlow.collect { isAuthenticated ->
                _uiState.update { it.copy(isAuthenticated = isAuthenticated) }
                Log.d(TAG, "Auth State Changed: isAuth=$isAuthenticated")

                if (isAuthenticated) {
                    observeUserTickets()
                } else {
                    _uiState.update { it.copy(upcomingTickets = emptyList(), pastTickets = emptyList(), isLoading = false) }
                }
            }
        }
    }

    private fun observeEvents() {
        viewModelScope.launch {
            eventRepository.allEvents.collect { events ->
                Log.d(TAG, "Events Cache updated: ${events.size} events found")
                eventsCache = events.associateBy { it.id ?: "" }
            }
        }
    }

    private fun observeUserTickets() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            ticketRepository.getUserTickets().collect { tickets ->
                Log.d(TAG, "Received ${tickets.size} tickets from repository")

                // Enrich tickets
                val enrichedTickets = tickets.map { ticket ->
                    val event = eventsCache[ticket.eventId]
                    if (event == null) {
                        Log.w(TAG, "WARNING: No event found for ticket ${ticket.id} (Event ID: ${ticket.eventId})")
                        ticket
                    } else {
                        // Use event's start_time and image URL
                        ticket.copy(
                            eventImageUrl = event.imageUrl,
                            startTime = event.startTime
                        )
                    }
                }

                // Filter based on ticket's startTime
                val upcoming = enrichedTickets.filter {
                    val isUp = it.isUpcoming
                    // FIX: Changed 'ticket.id' to 'it.id'
                    if (!isUp) Log.v(TAG, "Ticket ${it.id} filtered out of upcoming. Status: ${it.status}, Date: ${it.startDate}")
                    isUp
                }

                val past = enrichedTickets.filter { it.isPast }

                Log.d(TAG, "Filtering Complete -> Upcoming: ${upcoming.size}, Past: ${past.size}")

                _uiState.update {
                    it.copy(
                        upcomingTickets = upcoming,
                        pastTickets = past,
                        isLoading = false
                    )
                }
            }
        }
    }
}