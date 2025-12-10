package com.burner.app.services;

import android.content.Context;
import android.util.Log;
import androidx.annotation.StringRes;
import com.google.firebase.functions.FirebaseFunctions;
import com.burner.app.data.models.Event;
import com.burner.app.data.models.PaymentIntentResponse;
import com.burner.app.data.models.PaymentState;
import com.burner.app.data.models.SavedCard;
import com.stripe.android.PaymentConfiguration;
import com.stripe.android.Stripe;
import com.stripe.android.model.ConfirmPaymentIntentParams;
import com.stripe.android.model.PaymentMethodCreateParams;
import dagger.hilt.android.qualifiers.ApplicationContext;
import kotlinx.coroutines.Dispatchers;
import kotlinx.coroutines.flow.StateFlow;
import javax.inject.Inject;
import javax.inject.Singleton;

/**
 * Payment Service matching iOS StripePaymentService functionality
 */
@javax.inject.Singleton()
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u009a\u0001\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u000b\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0006\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0014\b\u0007\u0018\u0000 T2\u00020\u0001:\u0001TB!\b\u0007\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\u0018\u0010!\u001a\u00020\"2\u0006\u0010#\u001a\u00020$2\b\b\u0002\u0010%\u001a\u00020&J\u0006\u0010\'\u001a\u00020(J \u0010)\u001a\u00020*2\u0006\u0010+\u001a\u00020\u000b2\b\b\u0002\u0010,\u001a\u00020&H\u0082@\u00a2\u0006\u0002\u0010-J.\u0010.\u001a\b\u0012\u0004\u0012\u0002000/2\u0006\u00101\u001a\u00020\u000b2\b\b\u0002\u0010%\u001a\u00020&H\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b2\u0010-J$\u00103\u001a\b\u0012\u0004\u0012\u00020(0/2\u0006\u00104\u001a\u00020\u000bH\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b5\u00106J$\u00107\u001a\u0010\u0012\u0004\u0012\u00020\u000b\u0012\u0004\u0012\u00020\u000b\u0018\u0001082\u0006\u00101\u001a\u00020\u000bH\u0082@\u00a2\u0006\u0002\u00106J$\u00109\u001a\u00020(2\u0006\u0010:\u001a\u00020;2\u0012\u0010<\u001a\u000e\u0012\u0004\u0012\u00020*\u0012\u0004\u0012\u00020(0=H\u0002J\u0014\u0010>\u001a\u00020\r2\n\u0010?\u001a\u00060@j\u0002`AH\u0002J\u000e\u0010B\u001a\u00020(H\u0086@\u00a2\u0006\u0002\u0010CJ\u0016\u0010D\u001a\u00020(2\u0006\u00101\u001a\u00020\u000bH\u0086@\u00a2\u0006\u0002\u00106JJ\u0010E\u001a\u00020(2\u0006\u00101\u001a\u00020\u000b2\u0006\u0010F\u001a\u00020\u000b2\u0006\u0010G\u001a\u00020&2\u0006\u0010H\u001a\u00020&2\u0006\u0010I\u001a\u00020\u000b2\u0012\u0010<\u001a\u000e\u0012\u0004\u0012\u00020*\u0012\u0004\u0012\u00020(0=H\u0086@\u00a2\u0006\u0002\u0010JJ2\u0010K\u001a\u00020(2\u0006\u00101\u001a\u00020\u000b2\u0006\u00104\u001a\u00020\u000b2\u0012\u0010<\u001a\u000e\u0012\u0004\u0012\u00020*\u0012\u0004\u0012\u00020(0=H\u0086@\u00a2\u0006\u0002\u0010LJ\u0006\u0010M\u001a\u00020(JF\u0010N\u001a\b\u0012\u0004\u0012\u00020(0/2\u0006\u0010F\u001a\u00020\u000b2\u0006\u0010G\u001a\u00020&2\u0006\u0010H\u001a\u00020&2\u0006\u0010I\u001a\u00020\u000b2\b\b\u0002\u0010O\u001a\u00020\rH\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\bP\u0010QJ$\u0010R\u001a\b\u0012\u0004\u0012\u00020(0/2\u0006\u00104\u001a\u00020\u000bH\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\bS\u00106R\u0016\u0010\t\u001a\n\u0012\u0006\u0012\u0004\u0018\u00010\u000b0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\f\u001a\b\u0012\u0004\u0012\u00020\r0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u000f0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001a\u0010\u0010\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00120\u00110\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0019\u0010\u0013\u001a\n\u0012\u0006\u0012\u0004\u0018\u00010\u000b0\u0014\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0016R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\r0\u0014\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0016R\u0017\u0010\u0018\u001a\b\u0012\u0004\u0012\u00020\u000f0\u0014\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u0016R\u0010\u0010\u001a\u001a\u0004\u0018\u00010\u000bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u001b\u001a\u0004\u0018\u00010\u000bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u001c\u001a\u0004\u0018\u00010\u000bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u001d\u0010\u001d\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00120\u00110\u0014\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001e\u0010\u0016R\u000e\u0010\u001f\u001a\u00020 X\u0082.\u00a2\u0006\u0002\n\u0000\u0082\u0002\u000b\n\u0002\b!\n\u0005\b\u00a1\u001e0\u0001\u00a8\u0006U"}, d2 = {"Lcom/burner/app/services/PaymentService;", "", "context", "Landroid/content/Context;", "functions", "Lcom/google/firebase/functions/FirebaseFunctions;", "authService", "Lcom/burner/app/services/AuthService;", "(Landroid/content/Context;Lcom/google/firebase/functions/FirebaseFunctions;Lcom/burner/app/services/AuthService;)V", "_errorMessage", "Lkotlinx/coroutines/flow/MutableStateFlow;", "", "_isProcessing", "", "_paymentState", "Lcom/burner/app/data/models/PaymentState;", "_savedCards", "", "Lcom/burner/app/data/models/SavedCard;", "errorMessage", "Lkotlinx/coroutines/flow/StateFlow;", "getErrorMessage", "()Lkotlinx/coroutines/flow/StateFlow;", "isProcessing", "paymentState", "getPaymentState", "preparedClientSecret", "preparedEventId", "preparedIntentId", "savedCards", "getSavedCards", "stripe", "Lcom/stripe/android/Stripe;", "calculateTotal", "", "event", "Lcom/burner/app/data/models/Event;", "quantity", "", "clearPreparedIntent", "", "confirmPurchase", "Lcom/burner/app/services/PaymentResult;", "paymentIntentId", "retryCount", "(Ljava/lang/String;ILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "createPaymentIntent", "Lkotlin/Result;", "Lcom/burner/app/data/models/PaymentIntentResponse;", "eventId", "createPaymentIntent-0E7RQCE", "deletePaymentMethod", "paymentMethodId", "deletePaymentMethod-gIAlu-s", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getPaymentIntent", "Lkotlin/Pair;", "handleError", "error", "Lcom/burner/app/services/PaymentError;", "onResult", "Lkotlin/Function1;", "isNetworkError", "e", "Ljava/lang/Exception;", "Lkotlin/Exception;", "loadSavedCards", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "preparePayment", "processCardPayment", "cardNumber", "expiryMonth", "expiryYear", "cvc", "(Ljava/lang/String;Ljava/lang/String;IILjava/lang/String;Lkotlin/jvm/functions/Function1;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "processSavedCardPayment", "(Ljava/lang/String;Ljava/lang/String;Lkotlin/jvm/functions/Function1;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "resetPaymentState", "savePaymentMethod", "setAsDefault", "savePaymentMethod-hUnOzRk", "(Ljava/lang/String;IILjava/lang/String;ZLkotlin/coroutines/Continuation;)Ljava/lang/Object;", "setDefaultPaymentMethod", "setDefaultPaymentMethod-gIAlu-s", "Companion", "app_debug"})
public final class PaymentService {
    @org.jetbrains.annotations.NotNull()
    private final android.content.Context context = null;
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.functions.FirebaseFunctions functions = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    @org.jetbrains.annotations.NotNull()
    private static final java.lang.String TAG = "PaymentService";
    @org.jetbrains.annotations.NotNull()
    private static final java.lang.String STRIPE_PUBLISHABLE_KEY = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe";
    private static final int MAX_RETRIES = 3;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.data.models.PaymentState> _paymentState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.data.models.PaymentState> paymentState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<java.util.List<com.burner.app.data.models.SavedCard>> _savedCards = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<java.util.List<com.burner.app.data.models.SavedCard>> savedCards = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<java.lang.Boolean> _isProcessing = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<java.lang.Boolean> isProcessing = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<java.lang.String> _errorMessage = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<java.lang.String> errorMessage = null;
    @org.jetbrains.annotations.Nullable()
    private java.lang.String preparedClientSecret;
    @org.jetbrains.annotations.Nullable()
    private java.lang.String preparedIntentId;
    @org.jetbrains.annotations.Nullable()
    private java.lang.String preparedEventId;
    private com.stripe.android.Stripe stripe;
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.services.PaymentService.Companion Companion = null;
    
    @javax.inject.Inject()
    public PaymentService(@dagger.hilt.android.qualifiers.ApplicationContext()
    @org.jetbrains.annotations.NotNull()
    android.content.Context context, @org.jetbrains.annotations.NotNull()
    com.google.firebase.functions.FirebaseFunctions functions, @org.jetbrains.annotations.NotNull()
    com.burner.app.services.AuthService authService) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.data.models.PaymentState> getPaymentState() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<java.util.List<com.burner.app.data.models.SavedCard>> getSavedCards() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<java.lang.Boolean> isProcessing() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<java.lang.String> getErrorMessage() {
        return null;
    }
    
    /**
     * Prepare payment intent in advance (like iOS preparePayment)
     */
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object preparePayment(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    /**
     * Clear prepared payment intent
     */
    public final void clearPreparedIntent() {
    }
    
    /**
     * Process card payment (like iOS processCardPayment)
     */
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object processCardPayment(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    java.lang.String cardNumber, int expiryMonth, int expiryYear, @org.jetbrains.annotations.NotNull()
    java.lang.String cvc, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super com.burner.app.services.PaymentResult, kotlin.Unit> onResult, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    /**
     * Process saved card payment (like iOS processSavedCardPayment)
     */
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object processSavedCardPayment(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    java.lang.String paymentMethodId, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super com.burner.app.services.PaymentResult, kotlin.Unit> onResult, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    /**
     * Confirm purchase and create ticket (with retry logic like iOS)
     */
    private final java.lang.Object confirmPurchase(java.lang.String paymentIntentId, int retryCount, kotlin.coroutines.Continuation<? super com.burner.app.services.PaymentResult> $completion) {
        return null;
    }
    
    /**
     * Get payment intent (uses prepared if available)
     */
    private final java.lang.Object getPaymentIntent(java.lang.String eventId, kotlin.coroutines.Continuation<? super kotlin.Pair<java.lang.String, java.lang.String>> $completion) {
        return null;
    }
    
    /**
     * Load saved payment methods
     */
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object loadSavedCards(@org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    /**
     * Calculate total price
     */
    public final double calculateTotal(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.Event event, int quantity) {
        return 0.0;
    }
    
    /**
     * Reset payment state
     */
    public final void resetPaymentState() {
    }
    
    private final void handleError(com.burner.app.services.PaymentError error, kotlin.jvm.functions.Function1<? super com.burner.app.services.PaymentResult, kotlin.Unit> onResult) {
    }
    
    private final boolean isNetworkError(java.lang.Exception e) {
        return false;
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0006X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\b"}, d2 = {"Lcom/burner/app/services/PaymentService$Companion;", "", "()V", "MAX_RETRIES", "", "STRIPE_PUBLISHABLE_KEY", "", "TAG", "app_debug"})
    public static final class Companion {
        
        private Companion() {
            super();
        }
    }
}