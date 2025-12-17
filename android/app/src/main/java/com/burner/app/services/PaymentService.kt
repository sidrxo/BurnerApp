package com.burner.app.services

import android.content.Context
import android.util.Log
import com.burner.app.data.BurnerSupabaseClient
import com.stripe.android.PaymentConfiguration
import com.stripe.android.paymentsheet.PaymentSheet
import dagger.hilt.android.qualifiers.ApplicationContext
import io.github.jan.supabase.functions.functions
import kotlinx.coroutines.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.pow

@Singleton
class PaymentService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val supabase: BurnerSupabaseClient
) {
    companion object {
        private const val TAG = "PaymentService"
        // Ensure this matches your Stripe Dashboard
        private const val STRIPE_PUBLISHABLE_KEY = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"
    }

    // Preparation State (Matching iOS Logic)
    private var preparedClientSecret: String? = null
    private var preparedIntentId: String? = null
    private var preparedEventId: String? = null
    private var cleanupJob: Job? = null
    private val isPreparing = AtomicBoolean(false)

    init {
        PaymentConfiguration.init(context, STRIPE_PUBLISHABLE_KEY)
    }

    @Serializable
    data class CreateIntentRequest(
        val eventId: String
    )

    @Serializable
    data class CreateIntentResponse(
        val clientSecret: String,
        val paymentIntentId: String,
        val amount: Double,
        val eventName: String,
        val currency: String
    )

    @Serializable
    data class ConfirmPurchaseRequest(
        @SerialName("payment_intent_id")
        val paymentIntentId: String
    )

    @Serializable
    data class ConfirmPurchaseResponse(
        val success: Boolean,
        val ticketId: String?,
        val ticketNumber: String?,
        val message: String?
    )

    data class PaymentIntentConfig(
        val clientSecret: String,
        val paymentIntentId: String
    )

    data class PaymentResult(
        val success: Boolean,
        val message: String,
        val ticketId: String?,
        val ticketNumber: String? = null
    )

    // ------------------------------------------------------------------------
    // Public Methods
    // ------------------------------------------------------------------------

    /**
     * Pre-loads a PaymentIntent to speed up the UI when the user eventually clicks buy.
     * Matches iOS preparePayment(eventId:)
     */
    suspend fun preparePayment(eventId: String) = withContext(Dispatchers.IO) {
        if (isPreparing.get()) return@withContext
        if (preparedEventId == eventId && preparedIntentId != null) return@withContext

        // Cancel previous cleanup timer
        cleanupJob?.cancel()
        isPreparing.set(true)

        try {
            val result = createPaymentIntent(eventId)

            preparedClientSecret = result.clientSecret
            preparedIntentId = result.paymentIntentId
            preparedEventId = eventId

            Log.d(TAG, "Payment prepared for event: $eventId")

            // Auto-clear after 10 minutes (Matching iOS logic)
            cleanupJob = launch {
                delay(10 * 60 * 1000L)
                clearPreparedIntent(result.paymentIntentId)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to prepare payment: ${e.message}")
        } finally {
            isPreparing.set(false)
        }
    }

    /**
     * Gets config for PaymentSheet. Uses prepared intent if available, otherwise creates new.
     * Matches iOS withPaymentIntent logic.
     */
    suspend fun getPaymentConfig(eventId: String): Result<PaymentIntentConfig> = withContext(Dispatchers.IO) {
        try {
            if (supabase.auth.currentUserOrNull() == null) {
                return@withContext Result.failure(Exception("Please sign in to purchase tickets"))
            }

            // Consume prepared intent if matches
            if (preparedEventId == eventId && preparedIntentId != null && preparedClientSecret != null) {
                Log.d(TAG, "Using prepared payment intent")
                val config = PaymentIntentConfig(preparedClientSecret!!, preparedIntentId!!)
                clearPreparedIntent(preparedIntentId) // Clear local cache as we are consuming it
                return@withContext Result.success(config)
            }

            // Otherwise create new
            val config = createPaymentIntent(eventId)
            Result.success(config)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting payment config: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Calls backend confirmPurchase with retry logic (Exponential backoff).
     * Matches iOS confirmPurchase with retryCount.
     */
    suspend fun confirmPurchaseWithRetry(paymentIntentId: String): PaymentResult = withContext(Dispatchers.IO) {
        val maxRetries = 3
        var currentAttempt = 0
        var lastException: Exception? = null

        while (currentAttempt <= maxRetries) {
            try {
                return@withContext confirmPurchaseCall(paymentIntentId)
            } catch (e: Exception) {
                lastException = e
                if (isNetworkError(e) && currentAttempt < maxRetries) {
                    val delayTime = 1000L * (2.0.pow(currentAttempt.toDouble())).toLong()
                    Log.w(TAG, "Network error, retrying ($currentAttempt/$maxRetries) after ${delayTime}ms")
                    delay(delayTime)
                    currentAttempt++
                } else {
                    break
                }
            }
        }

        // Final fallback error
        PaymentResult(
            success = false,
            message = lastException?.message ?: "Failed to confirm purchase",
            ticketId = null
        )
    }

    // ------------------------------------------------------------------------
    // Private Helpers
    // ------------------------------------------------------------------------

    private suspend fun createPaymentIntent(eventId: String): PaymentIntentConfig {
        val requestBody = CreateIntentRequest(eventId = eventId)

        val response = supabase.functions.invoke<CreateIntentResponse>(
            function = "create-payment-intent",
            body = requestBody
        )

        return PaymentIntentConfig(
            clientSecret = response.clientSecret,
            paymentIntentId = response.paymentIntentId
        )
    }

    private suspend fun confirmPurchaseCall(paymentIntentId: String): PaymentResult {
        val requestBody = ConfirmPurchaseRequest(paymentIntentId = paymentIntentId)

        val response = supabase.functions.invoke<ConfirmPurchaseResponse>(
            function = "confirm-purchase",
            body = requestBody
        )

        return PaymentResult(
            success = response.success,
            message = response.message ?: "Purchase completed",
            ticketId = response.ticketId,
            ticketNumber = response.ticketNumber
        )
    }

    private fun clearPreparedIntent(intentId: String?) {
        if (intentId == null || preparedIntentId == intentId) {
            preparedClientSecret = null
            preparedIntentId = null
            preparedEventId = null
            cleanupJob?.cancel()
            cleanupJob = null
        }
    }

    private fun isNetworkError(e: Exception): Boolean {
        return e is IOException ||
                e.message?.lowercase()?.contains("network") == true ||
                e.message?.lowercase()?.contains("timeout") == true ||
                e.message?.lowercase()?.contains("connection") == true
    }
}