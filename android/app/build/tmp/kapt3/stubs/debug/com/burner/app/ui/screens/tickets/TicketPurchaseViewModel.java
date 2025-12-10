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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000F\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0007\b\u0007\u0018\u00002\u00020\u0001B\u001f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\u000e\u0010\u0010\u001a\u00020\u00112\u0006\u0010\u0012\u001a\u00020\u0013J\u0006\u0010\u0014\u001a\u00020\u0011J\u000e\u0010\u0015\u001a\u00020\u00112\u0006\u0010\u0016\u001a\u00020\u0017J\u000e\u0010\u0018\u001a\u00020\u00112\u0006\u0010\u0019\u001a\u00020\u0013J\u000e\u0010\u001a\u001a\u00020\u00112\u0006\u0010\u001b\u001a\u00020\u0013J\u000e\u0010\u001c\u001a\u00020\u00112\u0006\u0010\u001d\u001a\u00020\u0013R\u0014\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\f\u001a\b\u0012\u0004\u0012\u00020\u000b0\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000f\u00a8\u0006\u001e"}, d2 = {"Lcom/burner/app/ui/screens/tickets/TicketPurchaseViewModel;", "Landroidx/lifecycle/ViewModel;", "eventRepository", "Lcom/burner/app/data/repository/EventRepository;", "ticketRepository", "Lcom/burner/app/data/repository/TicketRepository;", "paymentService", "Lcom/burner/app/services/PaymentService;", "(Lcom/burner/app/data/repository/EventRepository;Lcom/burner/app/data/repository/TicketRepository;Lcom/burner/app/services/PaymentService;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/tickets/TicketPurchaseUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "loadEvent", "", "eventId", "", "processPayment", "selectPaymentMethod", "method", "Lcom/burner/app/data/models/PaymentMethod;", "updateCardNumber", "number", "updateCvv", "cvv", "updateExpiryDate", "date", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class TicketPurchaseViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.EventRepository eventRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.TicketRepository ticketRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.PaymentService paymentService = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.tickets.TicketPurchaseUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.tickets.TicketPurchaseUiState> uiState = null;
    
    @javax.inject.Inject()
    public TicketPurchaseViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.EventRepository eventRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.TicketRepository ticketRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.services.PaymentService paymentService) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.tickets.TicketPurchaseUiState> getUiState() {
        return null;
    }
    
    public final void loadEvent(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId) {
    }
    
    public final void selectPaymentMethod(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.PaymentMethod method) {
    }
    
    public final void updateCardNumber(@org.jetbrains.annotations.NotNull()
    java.lang.String number) {
    }
    
    public final void updateExpiryDate(@org.jetbrains.annotations.NotNull()
    java.lang.String date) {
    }
    
    public final void updateCvv(@org.jetbrains.annotations.NotNull()
    java.lang.String cvv) {
    }
    
    public final void processPayment() {
    }
}