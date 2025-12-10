package com.burner.app.ui.screens.tickets;

import androidx.compose.foundation.layout.*;
import androidx.compose.foundation.lazy.grid.GridCells;
import androidx.compose.material.icons.Icons;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.layout.ContentScale;
import androidx.compose.ui.text.font.FontWeight;
import androidx.compose.ui.text.style.TextOverflow;
import com.burner.app.data.models.Ticket;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerTypography;
import java.text.SimpleDateFormat;
import java.util.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000D\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010 \n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\u001a\u0010\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u0003H\u0003\u001a\u0016\u0010\u0004\u001a\u00020\u00012\f\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a\u0016\u0010\u0007\u001a\u00020\u00012\f\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a$\u0010\t\u001a\u00020\u00012\u0006\u0010\n\u001a\u00020\u00032\u0012\u0010\u000b\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\fH\u0003\u001a\u001e\u0010\r\u001a\u00020\u00012\u0006\u0010\u000e\u001a\u00020\u000f2\f\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a*\u0010\u0011\u001a\u00020\u00012\f\u0010\u0012\u001a\b\u0012\u0004\u0012\u00020\u000f0\u00132\u0012\u0010\u0014\u001a\u000e\u0012\u0004\u0012\u00020\u0015\u0012\u0004\u0012\u00020\u00010\fH\u0003\u001a\u0016\u0010\u0016\u001a\u00020\u00012\f\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001aD\u0010\u0018\u001a\u00020\u00012\u0012\u0010\u0014\u001a\u000e\u0012\u0004\u0012\u00020\u0015\u0012\u0004\u0012\u00020\u00010\f2\f\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00010\u00062\u000e\b\u0002\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\u00010\u00062\b\b\u0002\u0010\u0019\u001a\u00020\u001aH\u0007\u001a\u0010\u0010\u001b\u001a\u00020\u00152\u0006\u0010\u001c\u001a\u00020\u001dH\u0002\u00a8\u0006\u001e"}, d2 = {"EmptyFilterState", "", "filter", "Lcom/burner/app/ui/screens/tickets/TicketFilter;", "NoTicketsEmptyState", "onExploreClick", "Lkotlin/Function0;", "SignedOutEmptyState", "onSignInClick", "TabBarSection", "selectedFilter", "onFilterSelected", "Lkotlin/Function1;", "TicketGridItem", "ticket", "Lcom/burner/app/data/models/Ticket;", "onClick", "TicketsGrid", "tickets", "", "onTicketClick", "", "TicketsHeader", "onSettingsClick", "TicketsScreen", "viewModel", "Lcom/burner/app/ui/screens/tickets/TicketsViewModel;", "formatDate", "date", "Ljava/util/Date;", "app_debug"})
public final class TicketsScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void TicketsScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onTicketClick, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onSignInClick, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onSettingsClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.tickets.TicketsViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TicketsHeader(kotlin.jvm.functions.Function0<kotlin.Unit> onSettingsClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TabBarSection(com.burner.app.ui.screens.tickets.TicketFilter selectedFilter, kotlin.jvm.functions.Function1<? super com.burner.app.ui.screens.tickets.TicketFilter, kotlin.Unit> onFilterSelected) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void SignedOutEmptyState(kotlin.jvm.functions.Function0<kotlin.Unit> onSignInClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void NoTicketsEmptyState(kotlin.jvm.functions.Function0<kotlin.Unit> onExploreClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void EmptyFilterState(com.burner.app.ui.screens.tickets.TicketFilter filter) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TicketsGrid(java.util.List<com.burner.app.data.models.Ticket> tickets, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onTicketClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TicketGridItem(com.burner.app.data.models.Ticket ticket, kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    private static final java.lang.String formatDate(java.util.Date date) {
        return null;
    }
}