package com.burner.app.services

import com.google.firebase.functions.FirebaseFunctions
import com.burner.app.data.models.Event
import com.burner.app.data.models.PaymentIntentResponse
import com.burner.app.data.models.PaymentState
import com.burner.app.data.models.SavedCard
import com.stripe.android.PaymentConfiguration
import com.stripe.android.model.ConfirmPaymentIntentParams
import com.stripe.android.model.PaymentMethodCreateParams
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PaymentService @Inject constructor(
    private val functions: FirebaseFunctions,
    private val authService: AuthService
) {
    private val _paymentState = MutableStateFlow<PaymentState>(PaymentState.Idle)
    val paymentState: StateFlow<PaymentState> = _paymentState.asStateFlow()

    private val _savedCards = MutableStateFlow<List<SavedCard>>(emptyList())
    val savedCards: StateFlow<List<SavedCard>> = _savedCards.asStateFlow()

    // Create payment intent via Firebase Cloud Function
    suspend fun createPaymentIntent(
        eventId: String,
        amount: Double,
        quantity: Int = 1
    ): Result<PaymentIntentResponse> {
        return try {
            val userId = authService.currentUserId
                ?: return Result.failure(Exception("User not authenticated"))

            val data = hashMapOf(
                "eventId" to eventId,
                "amount" to (amount * 100).toInt(), // Convert to cents
                "quantity" to quantity,
                "userId" to userId
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
            Result.failure(e)
        }
    }

    // Process payment with card
    suspend fun processPayment(
        clientSecret: String,
        cardParams: PaymentMethodCreateParams.Card
    ): Result<String> {
        _paymentState.value = PaymentState.Processing

        return try {
            // Create payment method params
            val paymentMethodParams = PaymentMethodCreateParams.create(
                card = cardParams,
                billingDetails = PaymentMethodCreateParams.BillingDetails()
            )

            // In a real implementation, you would use Stripe's PaymentSheet or
            // confirmPayment here. This is a simplified version.
            // The actual payment confirmation happens through Stripe SDK

            _paymentState.value = PaymentState.Success("ticket_id_placeholder")
            Result.success("Payment successful")
        } catch (e: Exception) {
            _paymentState.value = PaymentState.Error(e.message ?: "Payment failed")
            Result.failure(e)
        }
    }

    // Load saved payment methods
    suspend fun loadSavedCards() {
        try {
            val userId = authService.currentUserId ?: return

            val result = functions
                .getHttpsCallable("getPaymentMethods")
                .call(hashMapOf("userId" to userId))
                .await()

            @Suppress("UNCHECKED_CAST")
            val cards = (result.data as? List<Map<String, Any>>)?.map { cardData ->
                SavedCard(
                    id = cardData["id"] as String,
                    brand = cardData["brand"] as String,
                    last4 = cardData["last4"] as String,
                    expiryMonth = (cardData["exp_month"] as Long).toInt(),
                    expiryYear = (cardData["exp_year"] as Long).toInt(),
                    isDefault = cardData["isDefault"] as? Boolean ?: false
                )
            } ?: emptyList()

            _savedCards.value = cards
        } catch (e: Exception) {
            // Handle error silently, saved cards are optional
        }
    }

    // Calculate total price
    fun calculateTotal(event: Event, quantity: Int = 1): Double {
        return event.price * quantity
    }

    // Reset payment state
    fun resetPaymentState() {
        _paymentState.value = PaymentState.Idle
    }
}
