package com.burner.app.data.models

/**
 * Payment-related models for Stripe integration
 */

data class PaymentIntentResponse(
    val clientSecret: String,
    val paymentIntentId: String,
    val ephemeralKey: String? = null,
    val customerId: String? = null
)

data class SavedCard(
    val id: String,
    val brand: String,
    val last4: String,
    val expiryMonth: Int,
    val expiryYear: Int,
    val isDefault: Boolean = false
) {
    val displayName: String
        get() = "$brand •••• $last4"

    val expiryDisplay: String
        get() = "${expiryMonth.toString().padStart(2, '0')}/${expiryYear % 100}"
}

sealed class PaymentMethod {
    object GooglePay : PaymentMethod()
    data class Card(val savedCard: SavedCard? = null) : PaymentMethod()
    object NewCard : PaymentMethod()
}

sealed class PaymentState {
    object Idle : PaymentState()
    object Loading : PaymentState()
    object Processing : PaymentState()
    data class Success(val ticketId: String) : PaymentState()
    data class Error(val message: String) : PaymentState()
}

data class PurchaseRequest(
    val eventId: String,
    val quantity: Int = 1,
    val paymentMethodId: String? = null
)
