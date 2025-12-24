package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.shared.models.Ticket
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.TicketRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
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

            // Collect the Flow from the repository
            ticketRepository.getTicketFlow(ticketId).collect { ticket: Ticket? ->
                if (ticket != null) {
                    // Fetch event details to get the start time / image
                    // Note: getEvent is a suspend function, which is allowed here
                    val event = eventRepository.getEvent(ticket.eventId)

                    val enrichedTicket = if (event != null) {
                        ticket.copy(
                            startTime = event.startTime,
                            eventImageUrl = event.imageUrl
                        )
                    } else {
                        ticket
                    }

                    _uiState.update {
                        it.copy(ticket = enrichedTicket, isLoading = false)
                    }
                } else {
                    _uiState.update {
                        it.copy(ticket = null, isLoading = false, error = "Ticket not found")
                    }
                }
            }
        }
    }
}