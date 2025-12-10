package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Ticket
import com.burner.app.data.repository.TicketRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TicketsUiState(
    val tickets: List<Ticket> = emptyList(),
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class TicketsViewModel @Inject constructor(
    private val ticketRepository: TicketRepository,
    private val authService: AuthService
) : ViewModel() {

    private val _uiState = MutableStateFlow(TicketsUiState())
    val uiState: StateFlow<TicketsUiState> = _uiState.asStateFlow()

    init {
        observeAuthState()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                val isAuthenticated = user != null
                _uiState.update { it.copy(isAuthenticated = isAuthenticated) }

                if (isAuthenticated) {
                    loadTickets()
                } else {
                    _uiState.update { it.copy(tickets = emptyList(), isLoading = false) }
                }
            }
        }
    }

    private fun loadTickets() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            ticketRepository.getUserTickets().collect { tickets ->
                _uiState.update {
                    it.copy(tickets = tickets, isLoading = false)
                }
            }
        }
    }
}
