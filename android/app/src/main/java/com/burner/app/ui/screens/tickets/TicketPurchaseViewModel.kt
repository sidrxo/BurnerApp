package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.models.PaymentMethod
import com.burner.app.data.models.PaymentState
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.TicketRepository
import com.burner.app.services.PaymentService
import com.google.firebase.Timestamp
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TicketPurchaseUiState(
    val event: Event? = null,
    val quantity: Int = 1,
    val totalPrice: Double = 0.0,
    val selectedPaymentMethod: PaymentMethod? = null,
    val cardNumber: String = "",
    val expiryDate: String = "",
    val cvv: String = "",
    val paymentState: PaymentState = PaymentState.Idle,
    val isLoading: Boolean = true
) {
    val isPaymentValid: Boolean
        get() = when (selectedPaymentMethod) {
            is PaymentMethod.GooglePay -> true
            is PaymentMethod.NewCard -> {
                cardNumber.length >= 15 &&
                expiryDate.length == 5 &&
                cvv.length >= 3
            }
            is PaymentMethod.Card -> true
            null -> false
        }
}

@HiltViewModel
class TicketPurchaseViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val ticketRepository: TicketRepository,
    private val paymentService: PaymentService
) : ViewModel() {

    private val _uiState = MutableStateFlow(TicketPurchaseUiState())
    val uiState: StateFlow<TicketPurchaseUiState> = _uiState.asStateFlow()

    fun loadEvent(eventId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            val event = eventRepository.getEvent(eventId)
            _uiState.update { state ->
                state.copy(
                    event = event,
                    totalPrice = (event?.price ?: 0.0) * state.quantity,
                    isLoading = false
                )
            }
        }
    }

    fun selectPaymentMethod(method: PaymentMethod) {
        _uiState.update { it.copy(selectedPaymentMethod = method) }
    }

    fun updateCardNumber(number: String) {
        // Format card number with spaces
        val cleaned = number.filter { it.isDigit() }
        val formatted = cleaned.chunked(4).joinToString(" ")
        _uiState.update { it.copy(cardNumber = formatted) }
    }

    fun updateExpiryDate(date: String) {
        // Format expiry date with slash
        val cleaned = date.filter { it.isDigit() }
        val formatted = when {
            cleaned.length <= 2 -> cleaned
            else -> "${cleaned.take(2)}/${cleaned.drop(2).take(2)}"
        }
        _uiState.update { it.copy(expiryDate = formatted) }
    }

    fun updateCvv(cvv: String) {
        _uiState.update { it.copy(cvv = cvv.filter { it.isDigit() }) }
    }

    fun processPayment() {
        val state = _uiState.value
        val event = state.event ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(paymentState = PaymentState.Processing) }

            try {
                // Create payment intent
                val paymentIntentResult = paymentService.createPaymentIntent(
                    eventId = event.id ?: "",
                    amount = state.totalPrice,
                    quantity = state.quantity
                )

                paymentIntentResult.onSuccess { paymentIntent ->
                    // In a real implementation, you would use Stripe SDK to confirm payment
                    // For now, we'll simulate a successful payment and create the ticket

                    // Create ticket
                    val ticketResult = ticketRepository.createTicket(
                        eventId = event.id ?: "",
                        eventName = event.name,
                        venue = event.venue,
                        venueId = event.venueId,
                        startTime = event.startTime ?: Timestamp.now(),
                        totalPrice = state.totalPrice
                    )

                    ticketResult.onSuccess { ticketId ->
                        _uiState.update {
                            it.copy(paymentState = PaymentState.Success(ticketId))
                        }
                    }.onFailure { error ->
                        _uiState.update {
                            it.copy(paymentState = PaymentState.Error(error.message ?: "Failed to create ticket"))
                        }
                    }
                }.onFailure { error ->
                    _uiState.update {
                        it.copy(paymentState = PaymentState.Error(error.message ?: "Payment failed"))
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(paymentState = PaymentState.Error(e.message ?: "Payment failed"))
                }
            }
        }
    }
}
