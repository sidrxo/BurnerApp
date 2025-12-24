package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.shared.models.Event
import com.burner.app.data.repository.EventRepository
import com.burner.app.services.PaymentService
import com.stripe.android.paymentsheet.PaymentSheetResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TicketPurchaseUiState(
    val event: Event? = null,
    val quantity: Int = 1,
    val totalPrice: Double = 0.0,
    val isLoading: Boolean = true,
    val clientSecret: String? = null,
    val currentPaymentIntentId: String? = null,
    val isProcessing: Boolean = false,
    val purchaseSuccess: Boolean = false,
    val errorMessage: String? = null
)

@HiltViewModel
class TicketPurchaseViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val paymentService: PaymentService
) : ViewModel() {

    private val _uiState = MutableStateFlow(TicketPurchaseUiState())
    val uiState: StateFlow<TicketPurchaseUiState> = _uiState.asStateFlow()

    fun loadEvent(eventId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            val event = eventRepository.getEvent(eventId)

            if (event != null) {
                _uiState.update { state ->
                    state.copy(
                        event = event,
                        totalPrice = event.price * state.quantity,
                        isLoading = false
                    )
                }
                // Prepare payment in background
                paymentService.preparePayment(event.id ?: "")
            } else {
                _uiState.update { it.copy(isLoading = false, errorMessage = "Event not found") }
            }
        }
    }

    fun checkout(onReadyToLaunch: () -> Unit) {
        val eventId = _uiState.value.event?.id ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true, errorMessage = null) }

            val result = paymentService.getPaymentConfig(eventId)

            result.onSuccess { config ->
                _uiState.update {
                    it.copy(
                        clientSecret = config.clientSecret,
                        currentPaymentIntentId = config.paymentIntentId,
                        isProcessing = false
                    )
                }
                onReadyToLaunch()
            }.onFailure { error ->
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        errorMessage = error.localizedMessage ?: "Failed to initialize payment"
                    )
                }
            }
        }
    }

    fun onPaymentSheetResult(paymentResult: PaymentSheetResult) {
        when (paymentResult) {
            is PaymentSheetResult.Canceled -> {
                _uiState.update { it.copy(isProcessing = false) }
            }
            is PaymentSheetResult.Failed -> {
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        errorMessage = paymentResult.error.localizedMessage
                    )
                }
            }
            is PaymentSheetResult.Completed -> {
                confirmPurchase()
            }
        }
    }

    private fun confirmPurchase() {
        val paymentIntentId = _uiState.value.currentPaymentIntentId ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }

            val result = paymentService.confirmPurchaseWithRetry(paymentIntentId)

            if (result.success) {
                _uiState.update { it.copy(isProcessing = false, purchaseSuccess = true) }
            } else {
                _uiState.update {
                    it.copy(
                        isProcessing = false,
                        errorMessage = result.message
                    )
                }
            }
        }
    }
}