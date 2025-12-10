package com.burner.app.ui.screens.tickets;

import androidx.compose.foundation.layout.*;
import androidx.compose.foundation.lazy.grid.GridCells;
import androidx.compose.material.icons.Icons;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.graphics.Brush;
import androidx.compose.ui.layout.ContentScale;
import androidx.compose.ui.text.style.TextOverflow;
import com.burner.app.data.models.Ticket;
import com.burner.app.data.models.TicketStatus;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;
import java.text.SimpleDateFormat;
import java.util.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u00004\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\u001a\u0010\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u0003H\u0003\u001a\u001e\u0010\u0004\u001a\u00020\u00012\u0006\u0010\u0005\u001a\u00020\u00062\f\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\u00010\bH\u0003\u001a4\u0010\t\u001a\u00020\u00012\u0012\u0010\n\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u000b2\f\u0010\f\u001a\b\u0012\u0004\u0012\u00020\u00010\b2\b\b\u0002\u0010\r\u001a\u00020\u000eH\u0007\u001a\u0010\u0010\u000f\u001a\u00020\u00032\u0006\u0010\u0010\u001a\u00020\u0011H\u0002\u00a8\u0006\u0012"}, d2 = {"StatusBadge", "", "status", "", "TicketCard", "ticket", "Lcom/burner/app/data/models/Ticket;", "onClick", "Lkotlin/Function0;", "TicketsScreen", "onTicketClick", "Lkotlin/Function1;", "onSignInClick", "viewModel", "Lcom/burner/app/ui/screens/tickets/TicketsViewModel;", "formatShortDate", "date", "Ljava/util/Date;", "app_debug"})
public final class TicketsScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void TicketsScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onTicketClick, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onSignInClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.tickets.TicketsViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TicketCard(com.burner.app.data.models.Ticket ticket, kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void StatusBadge(java.lang.String status) {
    }
    
    private static final java.lang.String formatShortDate(java.util.Date date) {
        return null;
    }
}