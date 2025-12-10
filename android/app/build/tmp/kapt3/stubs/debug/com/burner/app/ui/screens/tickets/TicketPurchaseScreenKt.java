package com.burner.app.ui.screens.tickets;

import androidx.compose.foundation.layout.*;
import androidx.compose.foundation.text.KeyboardOptions;
import androidx.compose.material.icons.Icons;
import androidx.compose.material.icons.filled.*;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.layout.ContentScale;
import androidx.compose.ui.text.input.KeyboardType;
import androidx.compose.ui.text.style.TextAlign;
import androidx.compose.ui.text.style.TextOverflow;
import com.burner.app.data.models.PaymentState;
import com.burner.app.data.models.SavedCard;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;
import java.text.SimpleDateFormat;
import java.util.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000L\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u0006\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u000f\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010 \n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\u001a\u008c\u0001\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u00052\u0006\u0010\u0006\u001a\u00020\u00052\u0006\u0010\u0007\u001a\u00020\u00052\u0006\u0010\b\u001a\u00020\t2\u0006\u0010\n\u001a\u00020\t2\b\u0010\u000b\u001a\u0004\u0018\u00010\u00052\u0012\u0010\f\u001a\u000e\u0012\u0004\u0012\u00020\u0005\u0012\u0004\u0012\u00020\u00010\r2\u0012\u0010\u000e\u001a\u000e\u0012\u0004\u0012\u00020\u0005\u0012\u0004\u0012\u00020\u00010\r2\u0012\u0010\u000f\u001a\u000e\u0012\u0004\u0012\u00020\u0005\u0012\u0004\u0012\u00020\u00010\r2\f\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00010\u0011H\u0003\u001a \u0010\u0012\u001a\u00020\u00012\u0006\u0010\u0013\u001a\u00020\u00052\u0006\u0010\u0014\u001a\u00020\u00052\u0006\u0010\u0015\u001a\u00020\u0005H\u0003\u001a.\u0010\u0016\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0017\u001a\u00020\t2\f\u0010\u0018\u001a\b\u0012\u0004\u0012\u00020\u00010\u00112\u0006\u0010\n\u001a\u00020\tH\u0003\u001a\u0010\u0010\u0019\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u0003H\u0003\u001a4\u0010\u001a\u001a\u00020\u00012\u0006\u0010\u001b\u001a\u00020\u00052\u0006\u0010\u001c\u001a\u00020\t2\f\u0010\u001d\u001a\b\u0012\u0004\u0012\u00020\u00010\u00112\f\u0010\u001e\u001a\b\u0012\u0004\u0012\u00020\u00010\u0011H\u0003\u001a&\u0010\u001f\u001a\u00020\u00012\u0006\u0010 \u001a\u00020!2\u0006\u0010\"\u001a\u00020\t2\f\u0010#\u001a\b\u0012\u0004\u0012\u00020\u00010\u0011H\u0003\u001aj\u0010$\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\f\u0010%\u001a\b\u0012\u0004\u0012\u00020!0&2\b\u0010\'\u001a\u0004\u0018\u00010!2\u0006\u0010\n\u001a\u00020\t2\b\u0010\u000b\u001a\u0004\u0018\u00010\u00052\u0012\u0010(\u001a\u000e\u0012\u0004\u0012\u00020!\u0012\u0004\u0012\u00020\u00010\r2\f\u0010)\u001a\b\u0012\u0004\u0012\u00020\u00010\u00112\f\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00010\u0011H\u0003\u001a6\u0010*\u001a\u00020\u00012\u0006\u0010+\u001a\u00020\u00052\f\u0010\u001e\u001a\b\u0012\u0004\u0012\u00020\u00010\u00112\f\u0010,\u001a\b\u0012\u0004\u0012\u00020\u00010\u00112\b\b\u0002\u0010-\u001a\u00020.H\u0007\u001a\u0010\u0010/\u001a\u00020\u00052\u0006\u00100\u001a\u000201H\u0002\u00a8\u00062"}, d2 = {"CardInputStep", "", "totalPrice", "", "cardNumber", "", "expiryDate", "cvv", "isCardValid", "", "isProcessing", "errorMessage", "onCardNumberChange", "Lkotlin/Function1;", "onExpiryDateChange", "onCvvChange", "onPayClick", "Lkotlin/Function0;", "EventHeader", "imageUrl", "name", "venue", "PaymentMethodStep", "hasSavedCards", "onCardClick", "PriceSummary", "PurchaseTopBar", "title", "showBackButton", "onBackClick", "onDismiss", "SavedCardItem", "card", "Lcom/burner/app/data/models/SavedCard;", "isSelected", "onClick", "SavedCardsStep", "savedCards", "", "selectedCard", "onCardSelect", "onAddNewClick", "TicketPurchaseScreen", "eventId", "onPurchaseComplete", "viewModel", "Lcom/burner/app/ui/screens/tickets/TicketPurchaseViewModel;", "formatDate", "date", "Ljava/util/Date;", "app_debug"})
public final class TicketPurchaseScreenKt {
    
    /**
     * Ticket Purchase Screen matching iOS TicketPurchaseView
     */
    @androidx.compose.runtime.Composable()
    public static final void TicketPurchaseScreen(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onPurchaseComplete, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.tickets.TicketPurchaseViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void PurchaseTopBar(java.lang.String title, boolean showBackButton, kotlin.jvm.functions.Function0<kotlin.Unit> onBackClick, kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void EventHeader(java.lang.String imageUrl, java.lang.String name, java.lang.String venue) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void PriceSummary(double totalPrice) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void PaymentMethodStep(double totalPrice, boolean hasSavedCards, kotlin.jvm.functions.Function0<kotlin.Unit> onCardClick, boolean isProcessing) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void CardInputStep(double totalPrice, java.lang.String cardNumber, java.lang.String expiryDate, java.lang.String cvv, boolean isCardValid, boolean isProcessing, java.lang.String errorMessage, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onCardNumberChange, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onExpiryDateChange, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onCvvChange, kotlin.jvm.functions.Function0<kotlin.Unit> onPayClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void SavedCardsStep(double totalPrice, java.util.List<com.burner.app.data.models.SavedCard> savedCards, com.burner.app.data.models.SavedCard selectedCard, boolean isProcessing, java.lang.String errorMessage, kotlin.jvm.functions.Function1<? super com.burner.app.data.models.SavedCard, kotlin.Unit> onCardSelect, kotlin.jvm.functions.Function0<kotlin.Unit> onAddNewClick, kotlin.jvm.functions.Function0<kotlin.Unit> onPayClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void SavedCardItem(com.burner.app.data.models.SavedCard card, boolean isSelected, kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    private static final java.lang.String formatDate(java.util.Date date) {
        return null;
    }
}