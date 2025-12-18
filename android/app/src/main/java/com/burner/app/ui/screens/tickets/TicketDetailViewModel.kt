package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Ticket
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.TicketRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TicketDetailUiState(
    val ticket: Ticket? = null,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class TicketDetailViewModel @Inject constructor(
    private val ticketRepository: TicketRepository,
    private val eventRepository: EventRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TicketDetailUiState())
    val uiState: StateFlow<TicketDetailUiState> = _uiState.asStateFlow()

    fun loadTicket(ticketId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            ticketRepository.getTicketFlow(ticketId).collect { ticket ->
                if (ticket != null) {
                    // Enrich ticket with event's start_time
                    val event = eventRepository.getEvent(ticket.eventId)
                    val enrichedTicket = if (event != null) {
                        ticket.copy(startTime = event.startTime)
                    } else {
                        ticket
                    }

                    _uiState.update {
                        it.copy(ticket = enrichedTicket, isLoading = false)
                    }
                } else {
                    _uiState.update {
                        it.copy(ticket = null, isLoading = false)
                    }
                }
            }
        }
    }
}
