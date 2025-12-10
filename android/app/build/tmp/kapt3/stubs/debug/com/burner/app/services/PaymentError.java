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
 * Payment errors matching iOS PaymentError
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000D\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u000f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u0000 \n2\u00060\u0001j\u0002`\u0002:\f\b\t\n\u000b\f\r\u000e\u000f\u0010\u0011\u0012\u0013B\u000f\b\u0004\u0012\u0006\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\u0002\u0010\u0005R\u0014\u0010\u0003\u001a\u00020\u0004X\u0096\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0006\u0010\u0007\u0082\u0001\u000b\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u00a8\u0006\u001f"}, d2 = {"Lcom/burner/app/services/PaymentError;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "message", "", "(Ljava/lang/String;)V", "getMessage", "()Ljava/lang/String;", "Cancelled", "CardDeclined", "Companion", "EventSoldOut", "ExpiredCard", "InsufficientFunds", "InvalidCard", "InvalidResponse", "NetworkError", "NotAuthenticated", "PaymentFailed", "ProcessingError", "Lcom/burner/app/services/PaymentError$Cancelled;", "Lcom/burner/app/services/PaymentError$CardDeclined;", "Lcom/burner/app/services/PaymentError$EventSoldOut;", "Lcom/burner/app/services/PaymentError$ExpiredCard;", "Lcom/burner/app/services/PaymentError$InsufficientFunds;", "Lcom/burner/app/services/PaymentError$InvalidCard;", "Lcom/burner/app/services/PaymentError$InvalidResponse;", "Lcom/burner/app/services/PaymentError$NetworkError;", "Lcom/burner/app/services/PaymentError$NotAuthenticated;", "Lcom/burner/app/services/PaymentError$PaymentFailed;", "Lcom/burner/app/services/PaymentError$ProcessingError;", "app_debug"})
public abstract class PaymentError extends java.lang.Exception {
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String message = null;
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.services.PaymentError.Companion Companion = null;
    
    private PaymentError(java.lang.String message) {
        super();
    }
    
    @java.lang.Override()
    @org.jetbrains.annotations.NotNull()
    public java.lang.String getMessage() {
        return null;
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$Cancelled;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class Cancelled extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.Cancelled INSTANCE = null;
        
        private Cancelled() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$CardDeclined;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class CardDeclined extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.CardDeclined INSTANCE = null;
        
        private CardDeclined() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0012\u0010\u0003\u001a\u00020\u00042\n\u0010\u0005\u001a\u00060\u0006j\u0002`\u0007\u00a8\u0006\b"}, d2 = {"Lcom/burner/app/services/PaymentError$Companion;", "", "()V", "fromException", "Lcom/burner/app/services/PaymentError;", "e", "Ljava/lang/Exception;", "Lkotlin/Exception;", "app_debug"})
    public static final class Companion {
        
        private Companion() {
            super();
        }
        
        @org.jetbrains.annotations.NotNull()
        public final com.burner.app.services.PaymentError fromException(@org.jetbrains.annotations.NotNull()
        java.lang.Exception e) {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$EventSoldOut;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class EventSoldOut extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.EventSoldOut INSTANCE = null;
        
        private EventSoldOut() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$ExpiredCard;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class ExpiredCard extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.ExpiredCard INSTANCE = null;
        
        private ExpiredCard() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$InsufficientFunds;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class InsufficientFunds extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.InsufficientFunds INSTANCE = null;
        
        private InsufficientFunds() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$InvalidCard;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class InvalidCard extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.InvalidCard INSTANCE = null;
        
        private InvalidCard() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$InvalidResponse;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class InvalidResponse extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.InvalidResponse INSTANCE = null;
        
        private InvalidResponse() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$NetworkError;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class NetworkError extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.NetworkError INSTANCE = null;
        
        private NetworkError() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$NotAuthenticated;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class NotAuthenticated extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.NotAuthenticated INSTANCE = null;
        
        private NotAuthenticated() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$PaymentFailed;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class PaymentFailed extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.PaymentFailed INSTANCE = null;
        
        private PaymentFailed() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/services/PaymentError$ProcessingError;", "Lcom/burner/app/services/PaymentError;", "()V", "app_debug"})
    public static final class ProcessingError extends com.burner.app.services.PaymentError {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.services.PaymentError.ProcessingError INSTANCE = null;
        
        private ProcessingError() {
        }
    }
}