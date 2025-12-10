package com.burner.app.services;

import com.google.firebase.functions.FirebaseFunctions;
import com.burner.app.data.models.Event;
import com.burner.app.data.models.PaymentIntentResponse;
import com.burner.app.data.models.PaymentState;
import com.burner.app.data.models.SavedCard;
import com.stripe.android.PaymentConfiguration;
import com.stripe.android.model.PaymentMethod;
import com.stripe.android.model.ConfirmPaymentIntentParams;
import com.stripe.android.model.PaymentMethodCreateParams;
import kotlinx.coroutines.flow.StateFlow;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton()
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000h\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u0006\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0010\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0004\b\u0007\u0018\u00002\u00020\u0001B\u0017\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006J\u0018\u0010\u0013\u001a\u00020\u00142\u0006\u0010\u0015\u001a\u00020\u00162\b\b\u0002\u0010\u0017\u001a\u00020\u0018J6\u0010\u0019\u001a\b\u0012\u0004\u0012\u00020\u001b0\u001a2\u0006\u0010\u001c\u001a\u00020\u001d2\u0006\u0010\u001e\u001a\u00020\u00142\b\b\u0002\u0010\u0017\u001a\u00020\u0018H\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b\u001f\u0010 J\u000e\u0010!\u001a\u00020\"H\u0086@\u00a2\u0006\u0002\u0010#J,\u0010$\u001a\b\u0012\u0004\u0012\u00020\u001d0\u001a2\u0006\u0010%\u001a\u00020\u001d2\u0006\u0010&\u001a\u00020\'H\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b(\u0010)J\u0006\u0010*\u001a\u00020\"R\u0014\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001a\u0010\n\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\f0\u000b0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\r\u001a\b\u0012\u0004\u0012\u00020\t0\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u001d\u0010\u0011\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\f0\u000b0\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0010\u0082\u0002\u000b\n\u0002\b!\n\u0005\b\u00a1\u001e0\u0001\u00a8\u0006+"}, d2 = {"Lcom/burner/app/services/PaymentService;", "", "functions", "Lcom/google/firebase/functions/FirebaseFunctions;", "authService", "Lcom/burner/app/services/AuthService;", "(Lcom/google/firebase/functions/FirebaseFunctions;Lcom/burner/app/services/AuthService;)V", "_paymentState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/data/models/PaymentState;", "_savedCards", "", "Lcom/burner/app/data/models/SavedCard;", "paymentState", "Lkotlinx/coroutines/flow/StateFlow;", "getPaymentState", "()Lkotlinx/coroutines/flow/StateFlow;", "savedCards", "getSavedCards", "calculateTotal", "", "event", "Lcom/burner/app/data/models/Event;", "quantity", "", "createPaymentIntent", "Lkotlin/Result;", "Lcom/burner/app/data/models/PaymentIntentResponse;", "eventId", "", "amount", "createPaymentIntent-BWLJW6A", "(Ljava/lang/String;DILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "loadSavedCards", "", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "processPayment", "clientSecret", "cardParams", "Lcom/stripe/android/model/PaymentMethodCreateParams$Card;", "processPayment-0E7RQCE", "(Ljava/lang/String;Lcom/stripe/android/model/PaymentMethodCreateParams$Card;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "resetPaymentState", "app_debug"})
public final class PaymentService {
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.functions.FirebaseFunctions functions = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.data.models.PaymentState> _paymentState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.data.models.PaymentState> paymentState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<java.util.List<com.burner.app.data.models.SavedCard>> _savedCards = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<java.util.List<com.burner.app.data.models.SavedCard>> savedCards = null;
    
    @javax.inject.Inject()
    public PaymentService(@org.jetbrains.annotations.NotNull()
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
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object loadSavedCards(@org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    public final double calculateTotal(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.Event event, int quantity) {
        return 0.0;
    }
    
    public final void resetPaymentState() {
    }
}