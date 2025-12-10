package com.burner.app.ui.screens.tickets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.models.PaymentMethod
import com.burner.app.data.models.PaymentState
import com.burner.app.data.models.SavedCard
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.TicketRepository
import com.burner.app.services.PaymentService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Purchase step matching iOS PurchaseStep
 */
enum class PurchaseStep {
    PAYMENT_METHOD,
    CARD_INPUT,
    SAVED_CARDS
}

data class TicketPurchaseUiState(
    val event: Event? = null,
    val quantity: Int = 1,
    val totalPrice: Double = 0.0,
    val currentStep: PurchaseStep = PurchaseStep.PAYMENT_METHOD,
    val selectedPaymentMethod: PaymentMethod? = null,
    val selectedSavedCard: SavedCard? = null,
    val savedCards: List<SavedCard> = emptyList(),
    val cardNumber: String = "",
    val expiryDate: String = "",
    val cvv: String = "",
    val paymentState: PaymentState = PaymentState.Idle,
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
    val hasInitiatedPurchase: Boolean = false
) {
    val isCardValid: Boolean
        get() {
            val cleanNumber = cardNumber.filter { it.isDigit() }
            val cleanCvv = cvv.filter { it.isDigit() }
            return cleanNumber.length >= 15 &&
                   expiryDate.length == 5 &&
                   cleanCvv.length >= 3
        }

    val isPaymentValid: Boolean
        get() = when (currentStep) {
            PurchaseStep.PAYMENT_METHOD -> true
            PurchaseStep.CARD_INPUT -> isCardValid
            PurchaseStep.SAVED_CARDS -> selectedSavedCard != null
        }

    val expiryMonth: Int
        get() = expiryDate.split("/").getOrNull(0)?.toIntOrNull() ?: 0

    val expiryYear: Int
        get() {
            val year = expiryDate.split("/").getOrNull(1)?.toIntOrNull() ?: 0
            return if (year < 100) 2000 + year else year
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

    init {
        // Observe payment service state
        viewModelScope.launch {
            paymentService.paymentState.collect { state ->
                _uiState.update { it.copy(paymentState = state) }
            }
        }

        viewModelScope.launch {
            paymentService.savedCards.collect { cards ->
                _uiState.update { it.copy(savedCards = cards) }
            }
        }
    }

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

            // Load saved cards and prepare payment
            paymentService.loadSavedCards()
            event?.id?.let { paymentService.preparePayment(it) }
        }
    }

    fun setStep(step: PurchaseStep) {
        _uiState.update { it.copy(currentStep = step, errorMessage = null) }
    }

    fun goToCardInput() {
        _uiState.update { it.copy(currentStep = PurchaseStep.CARD_INPUT, errorMessage = null) }
    }

    fun goToSavedCards() {
        val state = _uiState.value
        if (state.savedCards.isNotEmpty()) {
            _uiState.update { it.copy(currentStep = PurchaseStep.SAVED_CARDS, errorMessage = null) }
        } else {
            _uiState.update { it.copy(currentStep = PurchaseStep.CARD_INPUT, errorMessage = null) }
        }
    }

    fun goBack() {
        _uiState.update {
            it.copy(
                currentStep = PurchaseStep.PAYMENT_METHOD,
                selectedSavedCard = null,
                cardNumber = "",
                expiryDate = "",
                cvv = "",
                errorMessage = null,
                hasInitiatedPurchase = false
            )
        }
    }

    fun selectPaymentMethod(method: PaymentMethod) {
        _uiState.update { it.copy(selectedPaymentMethod = method) }
    }

    fun selectSavedCard(card: SavedCard) {
        _uiState.update { it.copy(selectedSavedCard = card) }
    }

    fun updateCardNumber(number: String) {
        val cleaned = number.filter { it.isDigit() }
        val formatted = cleaned.chunked(4).joinToString(" ").take(19)
        _uiState.update { it.copy(cardNumber = formatted) }
    }

    fun updateExpiryDate(date: String) {
        val cleaned = date.filter { it.isDigit() }
        val formatted = when {
            cleaned.length <= 2 -> cleaned
            else -> "${cleaned.take(2)}/${cleaned.drop(2).take(2)}"
        }
        _uiState.update { it.copy(expiryDate = formatted) }
    }

    fun updateCvv(cvv: String) {
        _uiState.update { it.copy(cvv = cvv.filter { it.isDigit() }.take(4)) }
    }

    fun processCardPayment() {
        val state = _uiState.value
        val event = state.event ?: return
        val eventId = event.id ?: return

        if (state.hasInitiatedPurchase) return
        if (!state.isCardValid) return

        _uiState.update { it.copy(hasInitiatedPurchase = true, errorMessage = null) }

        viewModelScope.launch {
            paymentService.processCardPayment(
                eventId = eventId,
                cardNumber = state.cardNumber,
                expiryMonth = state.expiryMonth,
                expiryYear = state.expiryYear,
                cvc = state.cvv
            ) { result ->
                _uiState.update {
                    it.copy(
                        hasInitiatedPurchase = false,
                        errorMessage = if (!result.success) result.message else null
                    )
                }
            }
        }
    }

    fun processSavedCardPayment() {
        val state = _uiState.value
        val event = state.event ?: return
        val eventId = event.id ?: return
        val savedCard = state.selectedSavedCard ?: return

        if (state.hasInitiatedPurchase) return

        _uiState.update { it.copy(hasInitiatedPurchase = true, errorMessage = null) }

        viewModelScope.launch {
            paymentService.processSavedCardPayment(
                eventId = eventId,
                paymentMethodId = savedCard.id
            ) { result ->
                _uiState.update {
                    it.copy(
                        hasInitiatedPurchase = false,
                        errorMessage = if (!result.success) result.message else null
                    )
                }
            }
        }
    }

    fun resetState() {
        paymentService.resetPaymentState()
        _uiState.update {
            TicketPurchaseUiState(
                event = it.event,
                totalPrice = it.totalPrice,
                savedCards = it.savedCards
            )
        }
    }

    override fun onCleared() {
        super.onCleared()
        paymentService.clearPreparedIntent()
    }
}
