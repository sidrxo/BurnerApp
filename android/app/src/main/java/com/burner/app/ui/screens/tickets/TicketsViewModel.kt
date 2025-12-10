package com.burner.app.ui.screens.tickets

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

    private val _uiState = MutableStateFlow(TicketsUiState())
    val uiState: StateFlow<TicketsUiState> = _uiState.asStateFlow()

    private var eventsCache: Map<String, Event> = emptyMap()

    init {
        observeAuthState()
        observeEvents()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                val isAuthenticated = user != null
                _uiState.update { it.copy(isAuthenticated = isAuthenticated) }

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
                eventsCache = events.associateBy { it.id ?: "" }
            }
        }
    }

    private fun observeUserTickets() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            ticketRepository.getUserTickets().collect { tickets ->
                // Enrich tickets with event image URLs from cache
                val enrichedTickets = tickets.map { ticket ->
                    if (ticket.eventImageUrl.isNullOrEmpty()) {
                        // Get image from event cache
                        val event = eventsCache[ticket.eventId]
                        ticket.copy(eventImageUrl = event?.imageUrl)
                    } else {
                        ticket
                    }
                }

                // Filter based on ticket's own startTime, matching iOS behavior
                val upcoming = enrichedTickets.filter { it.isUpcoming }
                val past = enrichedTickets.filter { it.isPast }

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
