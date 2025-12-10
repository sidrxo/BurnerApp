package com.burner.app.ui.screens.tickets;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.models.PaymentMethod;
import com.burner.app.data.models.PaymentState;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.TicketRepository;
import com.burner.app.services.PaymentService;
import com.google.firebase.Timestamp;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00008\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0006\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b \b\u0086\b\u0018\u00002\u00020\u0001Bc\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0007\u0012\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\t\u0012\b\b\u0002\u0010\n\u001a\u00020\u000b\u0012\b\b\u0002\u0010\f\u001a\u00020\u000b\u0012\b\b\u0002\u0010\r\u001a\u00020\u000b\u0012\b\b\u0002\u0010\u000e\u001a\u00020\u000f\u0012\b\b\u0002\u0010\u0010\u001a\u00020\u0011\u00a2\u0006\u0002\u0010\u0012J\u000b\u0010#\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u0010$\u001a\u00020\u0005H\u00c6\u0003J\t\u0010%\u001a\u00020\u0007H\u00c6\u0003J\u000b\u0010&\u001a\u0004\u0018\u00010\tH\u00c6\u0003J\t\u0010\'\u001a\u00020\u000bH\u00c6\u0003J\t\u0010(\u001a\u00020\u000bH\u00c6\u0003J\t\u0010)\u001a\u00020\u000bH\u00c6\u0003J\t\u0010*\u001a\u00020\u000fH\u00c6\u0003J\t\u0010+\u001a\u00020\u0011H\u00c6\u0003Jg\u0010,\u001a\u00020\u00002\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00072\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\t2\b\b\u0002\u0010\n\u001a\u00020\u000b2\b\b\u0002\u0010\f\u001a\u00020\u000b2\b\b\u0002\u0010\r\u001a\u00020\u000b2\b\b\u0002\u0010\u000e\u001a\u00020\u000f2\b\b\u0002\u0010\u0010\u001a\u00020\u0011H\u00c6\u0001J\u0013\u0010-\u001a\u00020\u00112\b\u0010.\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010/\u001a\u00020\u0005H\u00d6\u0001J\t\u00100\u001a\u00020\u000bH\u00d6\u0001R\u0011\u0010\n\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014R\u0011\u0010\r\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0014R\u0013\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017R\u0011\u0010\f\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0014R\u0011\u0010\u0010\u001a\u00020\u0011\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0019R\u0011\u0010\u001a\u001a\u00020\u00118F\u00a2\u0006\u0006\u001a\u0004\b\u001a\u0010\u0019R\u0011\u0010\u000e\u001a\u00020\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u001cR\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u001eR\u0013\u0010\b\u001a\u0004\u0018\u00010\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010 R\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b!\u0010\"\u00a8\u00061"}, d2 = {"Lcom/burner/app/ui/screens/tickets/TicketPurchaseUiState;", "", "event", "Lcom/burner/app/data/models/Event;", "quantity", "", "totalPrice", "", "selectedPaymentMethod", "Lcom/burner/app/data/models/PaymentMethod;", "cardNumber", "", "expiryDate", "cvv", "paymentState", "Lcom/burner/app/data/models/PaymentState;", "isLoading", "", "(Lcom/burner/app/data/models/Event;IDLcom/burner/app/data/models/PaymentMethod;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/burner/app/data/models/PaymentState;Z)V", "getCardNumber", "()Ljava/lang/String;", "getCvv", "getEvent", "()Lcom/burner/app/data/models/Event;", "getExpiryDate", "()Z", "isPaymentValid", "getPaymentState", "()Lcom/burner/app/data/models/PaymentState;", "getQuantity", "()I", "getSelectedPaymentMethod", "()Lcom/burner/app/data/models/PaymentMethod;", "getTotalPrice", "()D", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "equals", "other", "hashCode", "toString", "app_debug"})
public final class TicketPurchaseUiState {
    @org.jetbrains.annotations.Nullable()
    private final com.burner.app.data.models.Event event = null;
    private final int quantity = 0;
    private final double totalPrice = 0.0;
    @org.jetbrains.annotations.Nullable()
    private final com.burner.app.data.models.PaymentMethod selectedPaymentMethod = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String cardNumber = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String expiryDate = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String cvv = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.models.PaymentState paymentState = null;
    private final boolean isLoading = false;
    
    public TicketPurchaseUiState(@org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.Event event, int quantity, double totalPrice, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.PaymentMethod selectedPaymentMethod, @org.jetbrains.annotations.NotNull()
    java.lang.String cardNumber, @org.jetbrains.annotations.NotNull()
    java.lang.String expiryDate, @org.jetbrains.annotations.NotNull()
    java.lang.String cvv, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.PaymentState paymentState, boolean isLoading) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.Event getEvent() {
        return null;
    }
    
    public final int getQuantity() {
        return 0;
    }
    
    public final double getTotalPrice() {
        return 0.0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.PaymentMethod getSelectedPaymentMethod() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getCardNumber() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getExpiryDate() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getCvv() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.PaymentState getPaymentState() {
        return null;
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    public final boolean isPaymentValid() {
        return false;
    }
    
    public TicketPurchaseUiState() {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.Event component1() {
        return null;
    }
    
    public final int component2() {
        return 0;
    }
    
    public final double component3() {
        return 0.0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.PaymentMethod component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component5() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component6() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component7() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.PaymentState component8() {
        return null;
    }
    
    public final boolean component9() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.tickets.TicketPurchaseUiState copy(@org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.Event event, int quantity, double totalPrice, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.PaymentMethod selectedPaymentMethod, @org.jetbrains.annotations.NotNull()
    java.lang.String cardNumber, @org.jetbrains.annotations.NotNull()
    java.lang.String expiryDate, @org.jetbrains.annotations.NotNull()
    java.lang.String cvv, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.PaymentState paymentState, boolean isLoading) {
        return null;
    }
    
    @java.lang.Override()
    public boolean equals(@org.jetbrains.annotations.Nullable()
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override()
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override()
    @org.jetbrains.annotations.NotNull()
    public java.lang.String toString() {
        return null;
    }
}