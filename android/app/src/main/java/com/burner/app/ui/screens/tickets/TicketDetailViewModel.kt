package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Ticket
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
    private val ticketRepository: TicketRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TicketDetailUiState())
    val uiState: StateFlow<TicketDetailUiState> = _uiState.asStateFlow()

    fun loadTicket(ticketId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            ticketRepository.getTicketFlow(ticketId).collect { ticket ->
                _uiState.update {
                    it.copy(ticket = ticket, isLoading = false)
                }
            }
        }
    }
}
