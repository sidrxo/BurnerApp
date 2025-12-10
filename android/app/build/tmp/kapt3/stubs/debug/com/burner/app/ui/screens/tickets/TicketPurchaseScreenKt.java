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
import com.burner.app.data.models.PaymentMethod;
import com.burner.app.data.models.PaymentState;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;
import java.text.SimpleDateFormat;
import java.util.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000<\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\u001a\\\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u00032\u0006\u0010\u0005\u001a\u00020\u00032\u0012\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u00072\u0012\u0010\b\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u00072\u0012\u0010\t\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u0007H\u0003\u001a6\u0010\n\u001a\u00020\u00012\u0006\u0010\u000b\u001a\u00020\f2\u0006\u0010\r\u001a\u00020\u00032\u0006\u0010\u000e\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u00102\f\u0010\u0011\u001a\b\u0012\u0004\u0012\u00020\u00010\u0012H\u0003\u001a6\u0010\u0013\u001a\u00020\u00012\u0006\u0010\u0014\u001a\u00020\u00032\f\u0010\u0015\u001a\b\u0012\u0004\u0012\u00020\u00010\u00122\f\u0010\u0016\u001a\b\u0012\u0004\u0012\u00020\u00010\u00122\b\b\u0002\u0010\u0017\u001a\u00020\u0018H\u0007\u001a\u0010\u0010\u0019\u001a\u00020\u00032\u0006\u0010\u001a\u001a\u00020\u001bH\u0002\u00a8\u0006\u001c"}, d2 = {"CardInputFields", "", "cardNumber", "", "expiryDate", "cvv", "onCardNumberChange", "Lkotlin/Function1;", "onExpiryDateChange", "onCvvChange", "PaymentMethodOption", "icon", "Landroidx/compose/ui/graphics/vector/ImageVector;", "title", "subtitle", "isSelected", "", "onClick", "Lkotlin/Function0;", "TicketPurchaseScreen", "eventId", "onDismiss", "onPurchaseComplete", "viewModel", "Lcom/burner/app/ui/screens/tickets/TicketPurchaseViewModel;", "formatDate", "date", "Ljava/util/Date;", "app_debug"})
public final class TicketPurchaseScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void TicketPurchaseScreen(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onPurchaseComplete, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.tickets.TicketPurchaseViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void PaymentMethodOption(androidx.compose.ui.graphics.vector.ImageVector icon, java.lang.String title, java.lang.String subtitle, boolean isSelected, kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void CardInputFields(java.lang.String cardNumber, java.lang.String expiryDate, java.lang.String cvv, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onCardNumberChange, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onExpiryDateChange, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onCvvChange) {
    }
    
    private static final java.lang.String formatDate(java.util.Date date) {
        return null;
    }
}