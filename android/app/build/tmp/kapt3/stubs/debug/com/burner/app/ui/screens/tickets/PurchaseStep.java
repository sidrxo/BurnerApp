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

/**
 * Purchase step matching iOS PurchaseStep
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0005\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005\u00a8\u0006\u0006"}, d2 = {"Lcom/burner/app/ui/screens/tickets/PurchaseStep;", "", "(Ljava/lang/String;I)V", "PAYMENT_METHOD", "CARD_INPUT", "SAVED_CARDS", "app_debug"})
public enum PurchaseStep {
    /*public static final*/ PAYMENT_METHOD /* = new PAYMENT_METHOD() */,
    /*public static final*/ CARD_INPUT /* = new CARD_INPUT() */,
    /*public static final*/ SAVED_CARDS /* = new SAVED_CARDS() */;
    
    PurchaseStep() {
    }
    
    @org.jetbrains.annotations.NotNull()
    public static kotlin.enums.EnumEntries<com.burner.app.ui.screens.tickets.PurchaseStep> getEntries() {
        return null;
    }
}