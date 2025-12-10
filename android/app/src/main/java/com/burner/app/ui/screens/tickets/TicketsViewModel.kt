package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.models.Ticket
import com.burner.app.data.models.TicketWithEventData
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.TicketRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TicketsUiState(
    val ticketsWithEvents: List<TicketWithEventData> = emptyList(),
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = true,
    val error: String? = null
) {
    // Helper to check if there are any past tickets
    val hasPastTickets: Boolean
        get() = ticketsWithEvents.any { it.event?.isPast == true || it.ticket.isPast }
}

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
                    loadTickets()
                } else {
                    _uiState.update { it.copy(ticketsWithEvents = emptyList(), isLoading = false) }
                }
            }
        }
    }

    private fun observeEvents() {
        viewModelScope.launch {
            eventRepository.observeEvents().collect { events ->
                eventsCache = events.associateBy { it.id ?: "" }
                // Re-map tickets with updated event data
                updateTicketsWithEvents()
            }
        }
    }

    private fun loadTickets() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            ticketRepository.getUserTickets().collect { tickets ->
                val ticketsWithEvents = tickets.map { ticket ->
                    val event = eventsCache[ticket.eventId] ?: createPlaceholderEvent(ticket)
                    TicketWithEventData(ticket, event)
                }
                _uiState.update {
                    it.copy(ticketsWithEvents = ticketsWithEvents, isLoading = false)
                }
            }
        }
    }

    private fun updateTicketsWithEvents() {
        val currentTickets = _uiState.value.ticketsWithEvents.map { it.ticket }
        if (currentTickets.isEmpty()) return

        val updated = currentTickets.map { ticket ->
            val event = eventsCache[ticket.eventId] ?: createPlaceholderEvent(ticket)
            TicketWithEventData(ticket, event)
        }
        _uiState.update { it.copy(ticketsWithEvents = updated) }
    }

    private fun createPlaceholderEvent(ticket: Ticket): Event {
        return Event(
            name = ticket.eventName,
            venue = ticket.venue,
            startTime = ticket.startTime,
            price = ticket.totalPrice,
            maxTickets = 100,
            ticketsSold = 0,
            imageUrl = "",
            isFeatured = false,
            description = null
        )
    }

    fun refreshTickets() {
        if (_uiState.value.isAuthenticated) {
            loadTickets()
        }
    }
}
