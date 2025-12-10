package com.burner.app.services

import android.content.Context
import android.util.Log
import androidx.annotation.StringRes
import com.google.firebase.functions.FirebaseFunctions
import com.burner.app.data.models.Event
import com.burner.app.data.models.PaymentIntentResponse
import com.burner.app.data.models.PaymentState
import com.burner.app.data.models.SavedCard
import com.stripe.android.PaymentConfiguration
import com.stripe.android.Stripe
import com.stripe.android.model.ConfirmPaymentIntentParams
import com.stripe.android.model.PaymentMethodCreateParams
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Payment Service matching iOS StripePaymentService functionality
 */
@Singleton
class PaymentService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val functions: FirebaseFunctions,
    private val authService: AuthService
) {
    companion object {
        private const val TAG = "PaymentService"
        private const val STRIPE_PUBLISHABLE_KEY = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"
        private const val MAX_RETRIES = 3
    }

    private val _paymentState = MutableStateFlow<PaymentState>(PaymentState.Idle)
    val paymentState: StateFlow<PaymentState> = _paymentState.asStateFlow()

    private val _savedCards = MutableStateFlow<List<SavedCard>>(emptyList())
    val savedCards: StateFlow<List<SavedCard>> = _savedCards.asStateFlow()

    private val _isProcessing = MutableStateFlow(false)
    val isProcessing: StateFlow<Boolean> = _isProcessing.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    // Prepared payment intent (for faster checkout like iOS)
    private var preparedClientSecret: String? = null
    private var preparedIntentId: String? = null
    private var preparedEventId: String? = null

    private lateinit var stripe: Stripe

    init {
        // Initialize Stripe
        PaymentConfiguration.init(context, STRIPE_PUBLISHABLE_KEY)
        stripe = Stripe(context, STRIPE_PUBLISHABLE_KEY)
    }

    /**
     * Prepare payment intent in advance (like iOS preparePayment)
     */
    suspend fun preparePayment(eventId: String) {
        if (_isProcessing.value) return
        if (preparedEventId == eventId && preparedIntentId != null) return

        try {
            val result = createPaymentIntent(eventId)
            result.onSuccess { response ->
                preparedClientSecret = response.clientSecret
                preparedIntentId = response.paymentIntentId
                preparedEventId = eventId
                Log.d(TAG, "Payment prepared for event: $eventId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to prepare payment: ${e.message}")
        }
    }

    /**
     * Clear prepared payment intent
     */
    fun clearPreparedIntent() {
        preparedClientSecret = null
        preparedIntentId = null
        preparedEventId = null
    }

    /**
     * Create payment intent via Firebase Cloud Function
     */
    suspend fun createPaymentIntent(
        eventId: String,
        quantity: Int = 1
    ): Result<PaymentIntentResponse> {
        return try {
            val userId = authService.currentUserId
                ?: return Result.failure(PaymentError.NotAuthenticated)

            val data = hashMapOf(
                "eventId" to eventId,
                "quantity" to quantity
            )

            val result = functions
                .getHttpsCallable("createPaymentIntent")
                .call(data)
                .await()

            @Suppress("UNCHECKED_CAST")
            val response = result.data as Map<String, Any>

            Result.success(
                PaymentIntentResponse(
                    clientSecret = response["clientSecret"] as String,
                    paymentIntentId = response["paymentIntentId"] as String,
                    ephemeralKey = response["ephemeralKey"] as? String,
                    customerId = response["customerId"] as? String
                )
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create payment intent: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Process card payment (like iOS processCardPayment)
     */
    suspend fun processCardPayment(
        eventId: String,
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String,
        onResult: (PaymentResult) -> Unit
    ) {
        if (_isProcessing.value) return

        _isProcessing.value = true
        _errorMessage.value = null
        _paymentState.value = PaymentState.Processing

        try {
            // Get or create payment intent
            val (clientSecret, intentId) = getPaymentIntent(eventId)
                ?: run {
                    handleError(PaymentError.InvalidResponse, onResult)
                    return
                }

            // Create card params
            val cardParams = PaymentMethodCreateParams.Card.Builder()
                .setNumber(cardNumber.replace(" ", ""))
                .setExpiryMonth(expiryMonth)
                .setExpiryYear(expiryYear)
                .setCvc(cvc)
                .build()

            val paymentMethodParams = PaymentMethodCreateParams.create(cardParams)

            // Create payment method
            val paymentMethod = withContext(Dispatchers.IO) {
                stripe.createPaymentMethodSynchronous(paymentMethodParams)
            } ?: run {
                handleError(PaymentError.InvalidCard, onResult)
                return
            }

            // Confirm payment intent (using SDK - server should set use_stripe_sdk: true)
            val confirmParams = ConfirmPaymentIntentParams
                .createWithPaymentMethodId(
                    paymentMethodId = paymentMethod.id!!,
                    clientSecret = clientSecret,
                    returnUrl = "burner://payment-return" // Add return URL for redirect flows
                )

            val paymentIntent = withContext(Dispatchers.IO) {
                stripe.confirmPaymentIntentSynchronous(confirmParams)
            }

            if (paymentIntent?.status?.name == "Succeeded") {
                // Confirm purchase and create ticket
                val ticketResult = confirmPurchase(intentId)
                _isProcessing.value = false
                _paymentState.value = if (ticketResult.success) {
                    PaymentState.Success(ticketResult.ticketId ?: "")
                } else {
                    PaymentState.Error(ticketResult.message)
                }
                onResult(ticketResult)
            } else {
                handleError(PaymentError.PaymentFailed, onResult)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Card payment error: ${e.message}")
            handleError(PaymentError.fromException(e), onResult)
        }
    }

    /**
     * Process saved card payment (like iOS processSavedCardPayment)
     */
    suspend fun processSavedCardPayment(
        eventId: String,
        paymentMethodId: String,
        onResult: (PaymentResult) -> Unit
    ) {
        if (_isProcessing.value) return

        _isProcessing.value = true
        _errorMessage.value = null
        _paymentState.value = PaymentState.Processing

        try {
            val (clientSecret, intentId) = getPaymentIntent(eventId)
                ?: run {
                    handleError(PaymentError.InvalidResponse, onResult)
                    return
                }

            // Confirm with saved payment method
            val confirmParams = ConfirmPaymentIntentParams
                .createWithPaymentMethodId(
                    paymentMethodId = paymentMethodId,
                    clientSecret = clientSecret,
                    returnUrl = "burner://payment-return" // Add return URL for redirect flows
                )

            val paymentIntent = withContext(Dispatchers.IO) {
                stripe.confirmPaymentIntentSynchronous(confirmParams)
            }

            if (paymentIntent?.status?.name == "Succeeded") {
                val ticketResult = confirmPurchase(intentId)
                _isProcessing.value = false
                _paymentState.value = if (ticketResult.success) {
                    PaymentState.Success(ticketResult.ticketId ?: "")
                } else {
                    PaymentState.Error(ticketResult.message)
                }
                onResult(ticketResult)
            } else {
                handleError(PaymentError.PaymentFailed, onResult)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Saved card payment error: ${e.message}")
            handleError(PaymentError.fromException(e), onResult)
        }
    }

    /**
     * Confirm purchase and create ticket (with retry logic like iOS)
     */
    private suspend fun confirmPurchase(
        paymentIntentId: String,
        retryCount: Int = 0
    ): PaymentResult {
        return try {
            val result = functions
                .getHttpsCallable("confirmPurchase")
                .call(hashMapOf("paymentIntentId" to paymentIntentId))
                .await()

            @Suppress("UNCHECKED_CAST")
            val data = result.data as Map<String, Any>
            val success = data["success"] as? Boolean ?: false
            val message = data["message"] as? String ?: "Purchase completed"
            val ticketId = data["ticketId"] as? String

            PaymentResult(success = success, message = message, ticketId = ticketId)

        } catch (e: Exception) {
            // Retry on network errors
            if (isNetworkError(e) && retryCount < MAX_RETRIES) {
                val delayMs = 1000L * (1 shl retryCount) // Exponential backoff: 1s, 2s, 4s
                Log.w(TAG, "Network error, retrying (${retryCount + 1}/$MAX_RETRIES) after ${delayMs}ms...")
                delay(delayMs)
                return confirmPurchase(paymentIntentId, retryCount + 1)
            }
            PaymentResult(success = false, message = e.message ?: "Failed to create ticket", ticketId = null)
        }
    }

    /**
     * Get payment intent (uses prepared if available)
     */
    private suspend fun getPaymentIntent(eventId: String): Pair<String, String>? {
        // Use prepared intent if available
        if (preparedEventId == eventId && preparedClientSecret != null && preparedIntentId != null) {
            val result = Pair(preparedClientSecret!!, preparedIntentId!!)
            clearPreparedIntent()
            return result
        }

        // Create new intent
        val result = createPaymentIntent(eventId)
        return result.getOrNull()?.let { Pair(it.clientSecret, it.paymentIntentId) }
    }

    /**
     * Load saved payment methods
     */
    suspend fun loadSavedCards() {
        try {
            val result = functions
                .getHttpsCallable("getPaymentMethods")
                .call()
                .await()

            @Suppress("UNCHECKED_CAST")
            val data = result.data as? Map<String, Any>
            val methods = data?.get("paymentMethods") as? List<Map<String, Any>>

            val cards = methods?.mapNotNull { cardData ->
                try {
                    SavedCard(
                        id = cardData["id"] as String,
                        brand = cardData["brand"] as? String ?: "card",
                        last4 = cardData["last4"] as String,
                        expiryMonth = (cardData["expMonth"] as? Long)?.toInt() ?: 0,
                        expiryYear = (cardData["expYear"] as? Long)?.toInt() ?: 0,
                        isDefault = cardData["isDefault"] as? Boolean ?: false
                    )
                } catch (e: Exception) {
                    null
                }
            } ?: emptyList()

            _savedCards.value = cards
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load saved cards: ${e.message}")
        }
    }

    /**
     * Save a new payment method
     */
    suspend fun savePaymentMethod(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvc: String,
        setAsDefault: Boolean = false
    ): Result<Unit> {
        return try {
            val cardParams = PaymentMethodCreateParams.Card.Builder()
                .setNumber(cardNumber.replace(" ", ""))
                .setExpiryMonth(expiryMonth)
                .setExpiryYear(expiryYear)
                .setCvc(cvc)
                .build()

            val paymentMethodParams = PaymentMethodCreateParams.create(cardParams)
            val paymentMethod = withContext(Dispatchers.IO) {
                stripe.createPaymentMethodSynchronous(paymentMethodParams)
            } ?: return Result.failure(PaymentError.InvalidCard)

            functions
                .getHttpsCallable("savePaymentMethod")
                .call(hashMapOf(
                    "paymentMethodId" to paymentMethod.id,
                    "setAsDefault" to setAsDefault
                ))
                .await()

            loadSavedCards()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Delete a payment method
     */
    suspend fun deletePaymentMethod(paymentMethodId: String): Result<Unit> {
        return try {
            functions
                .getHttpsCallable("deletePaymentMethod")
                .call(hashMapOf("paymentMethodId" to paymentMethodId))
                .await()

            loadSavedCards()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Set default payment method
     */
    suspend fun setDefaultPaymentMethod(paymentMethodId: String): Result<Unit> {
        return try {
            functions
                .getHttpsCallable("setDefaultPaymentMethod")
                .call(hashMapOf("paymentMethodId" to paymentMethodId))
                .await()

            loadSavedCards()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Calculate total price
     */
    fun calculateTotal(event: Event, quantity: Int = 1): Double {
        return event.price * quantity
    }

    /**
     * Reset payment state
     */
    fun resetPaymentState() {
        _paymentState.value = PaymentState.Idle
        _isProcessing.value = false
        _errorMessage.value = null
    }

    private fun handleError(error: PaymentError, onResult: (PaymentResult) -> Unit) {
        _isProcessing.value = false
        _errorMessage.value = error.message
        _paymentState.value = PaymentState.Error(error.message)
        onResult(PaymentResult(success = false, message = error.message, ticketId = null))
    }

    private fun isNetworkError(e: Exception): Boolean {
        val message = e.message?.lowercase() ?: ""
        return message.contains("network") ||
               message.contains("connection") ||
               message.contains("timeout") ||
               e is java.net.UnknownHostException ||
               e is java.net.SocketTimeoutException
    }
}

/**
 * Payment result matching iOS PaymentResult
 */
data class PaymentResult(
    val success: Boolean,
    val message: String,
    val ticketId: String?
)

/**
 * Payment errors matching iOS PaymentError
 */
sealed class PaymentError(override val message: String) : Exception(message) {
    object NotAuthenticated : PaymentError("Please sign in to purchase tickets")
    object InvalidResponse : PaymentError("Invalid response from server. Please try again.")
    object PaymentFailed : PaymentError("Payment failed. Please try again")
    object Cancelled : PaymentError("Payment was cancelled")
    object CardDeclined : PaymentError("Card declined. Please try another payment method")
    object InsufficientFunds : PaymentError("Insufficient funds. Please use another card")
    object ExpiredCard : PaymentError("Card expired. Please update your payment method")
    object NetworkError : PaymentError("Network error. Please check your connection and try again")
    object InvalidCard : PaymentError("Invalid card details. Please check and try again")
    object ProcessingError : PaymentError("Payment succeeded but ticket creation failed. Please contact support.")
    object EventSoldOut : PaymentError("This event is sold out")

    companion object {
        fun fromException(e: Exception): PaymentError {
            val message = e.message?.lowercase() ?: ""
            return when {
                message.contains("declined") -> CardDeclined
                message.contains("insufficient") -> InsufficientFunds
                message.contains("expired") -> ExpiredCard
                message.contains("invalid") -> InvalidCard
                message.contains("network") || message.contains("connection") -> NetworkError
                else -> PaymentFailed
            }
        }
    }
}
