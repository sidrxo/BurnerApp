package com.burner.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.repository.PreferencesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NotificationSettingsUiState(
    val eventReminders: Boolean = true,
    val newEvents: Boolean = true,
    val priceDrops: Boolean = false,
    val marketingEmails: Boolean = false,
    val ticketConfirmations: Boolean = true
)

@HiltViewModel
class NotificationSettingsViewModel @Inject constructor(
    private val preferencesRepository: PreferencesRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(NotificationSettingsUiState())
    val uiState: StateFlow<NotificationSettingsUiState> = _uiState.asStateFlow()

    fun setEventReminders(enabled: Boolean) {
        _uiState.update { it.copy(eventReminders = enabled) }
        // TODO: Save to preferences/backend
    }

    fun setNewEvents(enabled: Boolean) {
        _uiState.update { it.copy(newEvents = enabled) }
    }

    fun setPriceDrops(enabled: Boolean) {
        _uiState.update { it.copy(priceDrops = enabled) }
    }

    fun setMarketingEmails(enabled: Boolean) {
        _uiState.update { it.copy(marketingEmails = enabled) }
    }

    fun setTicketConfirmations(enabled: Boolean) {
        _uiState.update { it.copy(ticketConfirmations = enabled) }
    }
}
