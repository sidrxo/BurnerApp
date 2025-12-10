package com.burner.app.ui.screens.tickets;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.models.PaymentMethod;
import com.burner.app.data.models.PaymentState;
import com.burner.app.data.models.SavedCard;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.TicketRepository;
import com.burner.app.services.PaymentService;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000J\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0006\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b4\b\u0086\b\u0018\u00002\u00020\u0001B\u009f\u0001\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0007\u0012\b\b\u0002\u0010\b\u001a\u00020\t\u0012\n\b\u0002\u0010\n\u001a\u0004\u0018\u00010\u000b\u0012\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\r\u0012\u000e\b\u0002\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\r0\u000f\u0012\b\b\u0002\u0010\u0010\u001a\u00020\u0011\u0012\b\b\u0002\u0010\u0012\u001a\u00020\u0011\u0012\b\b\u0002\u0010\u0013\u001a\u00020\u0011\u0012\b\b\u0002\u0010\u0014\u001a\u00020\u0015\u0012\b\b\u0002\u0010\u0016\u001a\u00020\u0017\u0012\n\b\u0002\u0010\u0018\u001a\u0004\u0018\u00010\u0011\u0012\b\b\u0002\u0010\u0019\u001a\u00020\u0017\u00a2\u0006\u0002\u0010\u001aJ\u000b\u00108\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u00109\u001a\u00020\u0011H\u00c6\u0003J\t\u0010:\u001a\u00020\u0015H\u00c6\u0003J\t\u0010;\u001a\u00020\u0017H\u00c6\u0003J\u000b\u0010<\u001a\u0004\u0018\u00010\u0011H\u00c6\u0003J\t\u0010=\u001a\u00020\u0017H\u00c6\u0003J\t\u0010>\u001a\u00020\u0005H\u00c6\u0003J\t\u0010?\u001a\u00020\u0007H\u00c6\u0003J\t\u0010@\u001a\u00020\tH\u00c6\u0003J\u000b\u0010A\u001a\u0004\u0018\u00010\u000bH\u00c6\u0003J\u000b\u0010B\u001a\u0004\u0018\u00010\rH\u00c6\u0003J\u000f\u0010C\u001a\b\u0012\u0004\u0012\u00020\r0\u000fH\u00c6\u0003J\t\u0010D\u001a\u00020\u0011H\u00c6\u0003J\t\u0010E\u001a\u00020\u0011H\u00c6\u0003J\u00a3\u0001\u0010F\u001a\u00020\u00002\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00072\b\b\u0002\u0010\b\u001a\u00020\t2\n\b\u0002\u0010\n\u001a\u0004\u0018\u00010\u000b2\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\r2\u000e\b\u0002\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\r0\u000f2\b\b\u0002\u0010\u0010\u001a\u00020\u00112\b\b\u0002\u0010\u0012\u001a\u00020\u00112\b\b\u0002\u0010\u0013\u001a\u00020\u00112\b\b\u0002\u0010\u0014\u001a\u00020\u00152\b\b\u0002\u0010\u0016\u001a\u00020\u00172\n\b\u0002\u0010\u0018\u001a\u0004\u0018\u00010\u00112\b\b\u0002\u0010\u0019\u001a\u00020\u0017H\u00c6\u0001J\u0013\u0010G\u001a\u00020\u00172\b\u0010H\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010I\u001a\u00020\u0005H\u00d6\u0001J\t\u0010J\u001a\u00020\u0011H\u00d6\u0001R\u0011\u0010\u0010\u001a\u00020\u0011\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u001cR\u0011\u0010\b\u001a\u00020\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u001eR\u0011\u0010\u0013\u001a\u00020\u0011\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010\u001cR\u0013\u0010\u0018\u001a\u0004\u0018\u00010\u0011\u00a2\u0006\b\n\u0000\u001a\u0004\b \u0010\u001cR\u0013\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b!\u0010\"R\u0011\u0010\u0012\u001a\u00020\u0011\u00a2\u0006\b\n\u0000\u001a\u0004\b#\u0010\u001cR\u0011\u0010$\u001a\u00020\u00058F\u00a2\u0006\u0006\u001a\u0004\b%\u0010&R\u0011\u0010\'\u001a\u00020\u00058F\u00a2\u0006\u0006\u001a\u0004\b(\u0010&R\u0011\u0010\u0019\u001a\u00020\u0017\u00a2\u0006\b\n\u0000\u001a\u0004\b)\u0010*R\u0011\u0010+\u001a\u00020\u00178F\u00a2\u0006\u0006\u001a\u0004\b+\u0010*R\u0011\u0010\u0016\u001a\u00020\u0017\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010*R\u0011\u0010,\u001a\u00020\u00178F\u00a2\u0006\u0006\u001a\u0004\b,\u0010*R\u0011\u0010\u0014\u001a\u00020\u0015\u00a2\u0006\b\n\u0000\u001a\u0004\b-\u0010.R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b/\u0010&R\u0017\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\r0\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b0\u00101R\u0013\u0010\n\u001a\u0004\u0018\u00010\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b2\u00103R\u0013\u0010\f\u001a\u0004\u0018\u00010\r\u00a2\u0006\b\n\u0000\u001a\u0004\b4\u00105R\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b6\u00107\u00a8\u0006K"}, d2 = {"Lcom/burner/app/ui/screens/tickets/TicketPurchaseUiState;", "", "event", "Lcom/burner/app/data/models/Event;", "quantity", "", "totalPrice", "", "currentStep", "Lcom/burner/app/ui/screens/tickets/PurchaseStep;", "selectedPaymentMethod", "Lcom/burner/app/data/models/PaymentMethod;", "selectedSavedCard", "Lcom/burner/app/data/models/SavedCard;", "savedCards", "", "cardNumber", "", "expiryDate", "cvv", "paymentState", "Lcom/burner/app/data/models/PaymentState;", "isLoading", "", "errorMessage", "hasInitiatedPurchase", "(Lcom/burner/app/data/models/Event;IDLcom/burner/app/ui/screens/tickets/PurchaseStep;Lcom/burner/app/data/models/PaymentMethod;Lcom/burner/app/data/models/SavedCard;Ljava/util/List;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/burner/app/data/models/PaymentState;ZLjava/lang/String;Z)V", "getCardNumber", "()Ljava/lang/String;", "getCurrentStep", "()Lcom/burner/app/ui/screens/tickets/PurchaseStep;", "getCvv", "getErrorMessage", "getEvent", "()Lcom/burner/app/data/models/Event;", "getExpiryDate", "expiryMonth", "getExpiryMonth", "()I", "expiryYear", "getExpiryYear", "getHasInitiatedPurchase", "()Z", "isCardValid", "isPaymentValid", "getPaymentState", "()Lcom/burner/app/data/models/PaymentState;", "getQuantity", "getSavedCards", "()Ljava/util/List;", "getSelectedPaymentMethod", "()Lcom/burner/app/data/models/PaymentMethod;", "getSelectedSavedCard", "()Lcom/burner/app/data/models/SavedCard;", "getTotalPrice", "()D", "component1", "component10", "component11", "component12", "component13", "component14", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "equals", "other", "hashCode", "toString", "app_debug"})
public final class TicketPurchaseUiState {
    @org.jetbrains.annotations.Nullable()
    private final com.burner.app.data.models.Event event = null;
    private final int quantity = 0;
    private final double totalPrice = 0.0;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.ui.screens.tickets.PurchaseStep currentStep = null;
    @org.jetbrains.annotations.Nullable()
    private final com.burner.app.data.models.PaymentMethod selectedPaymentMethod = null;
    @org.jetbrains.annotations.Nullable()
    private final com.burner.app.data.models.SavedCard selectedSavedCard = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.SavedCard> savedCards = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String cardNumber = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String expiryDate = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String cvv = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.models.PaymentState paymentState = null;
    private final boolean isLoading = false;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String errorMessage = null;
    private final boolean hasInitiatedPurchase = false;
    
    public TicketPurchaseUiState(@org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.Event event, int quantity, double totalPrice, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.tickets.PurchaseStep currentStep, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.PaymentMethod selectedPaymentMethod, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.SavedCard selectedSavedCard, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.SavedCard> savedCards, @org.jetbrains.annotations.NotNull()
    java.lang.String cardNumber, @org.jetbrains.annotations.NotNull()
    java.lang.String expiryDate, @org.jetbrains.annotations.NotNull()
    java.lang.String cvv, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.PaymentState paymentState, boolean isLoading, @org.jetbrains.annotations.Nullable()
    java.lang.String errorMessage, boolean hasInitiatedPurchase) {
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
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.tickets.PurchaseStep getCurrentStep() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.PaymentMethod getSelectedPaymentMethod() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.SavedCard getSelectedSavedCard() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.SavedCard> getSavedCards() {
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
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getErrorMessage() {
        return null;
    }
    
    public final boolean getHasInitiatedPurchase() {
        return false;
    }
    
    public final boolean isCardValid() {
        return false;
    }
    
    public final boolean isPaymentValid() {
        return false;
    }
    
    public final int getExpiryMonth() {
        return 0;
    }
    
    public final int getExpiryYear() {
        return 0;
    }
    
    public TicketPurchaseUiState() {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.Event component1() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component10() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.PaymentState component11() {
        return null;
    }
    
    public final boolean component12() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component13() {
        return null;
    }
    
    public final boolean component14() {
        return false;
    }
    
    public final int component2() {
        return 0;
    }
    
    public final double component3() {
        return 0.0;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.tickets.PurchaseStep component4() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.PaymentMethod component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.SavedCard component6() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.SavedCard> component7() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component8() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component9() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.tickets.TicketPurchaseUiState copy(@org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.Event event, int quantity, double totalPrice, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.tickets.PurchaseStep currentStep, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.PaymentMethod selectedPaymentMethod, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.SavedCard selectedSavedCard, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.SavedCard> savedCards, @org.jetbrains.annotations.NotNull()
    java.lang.String cardNumber, @org.jetbrains.annotations.NotNull()
    java.lang.String expiryDate, @org.jetbrains.annotations.NotNull()
    java.lang.String cvv, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.PaymentState paymentState, boolean isLoading, @org.jetbrains.annotations.Nullable()
    java.lang.String errorMessage, boolean hasInitiatedPurchase) {
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