package com.burner.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.SavedCard
import com.burner.app.services.PaymentService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PaymentSettingsUiState(
    val savedCards: List<SavedCard> = emptyList(),
    val isLoading: Boolean = false
)

@HiltViewModel
class PaymentSettingsViewModel @Inject constructor(
    private val paymentService: PaymentService
) : ViewModel() {

    private val _uiState = MutableStateFlow(PaymentSettingsUiState())
    val uiState: StateFlow<PaymentSettingsUiState> = _uiState.asStateFlow()

    init {
        loadSavedCards()
    }

    private fun loadSavedCards() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

        }
    }

    fun removeCard(cardId: String) {
        // TODO: Implement card removal via Stripe
        viewModelScope.launch {
            _uiState.update { state ->
                state.copy(savedCards = state.savedCards.filter { it.id != cardId })
            }
        }
    }
}
