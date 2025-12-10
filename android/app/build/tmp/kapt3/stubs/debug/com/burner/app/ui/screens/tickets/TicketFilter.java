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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0004\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004\u00a8\u0006\u0005"}, d2 = {"Lcom/burner/app/ui/screens/tickets/TicketFilter;", "", "(Ljava/lang/String;I)V", "UPCOMING", "PAST", "app_debug"})
public enum TicketFilter {
    /*public static final*/ UPCOMING /* = new UPCOMING() */,
    /*public static final*/ PAST /* = new PAST() */;
    
    TicketFilter() {
    }
    
    @org.jetbrains.annotations.NotNull()
    public static kotlin.enums.EnumEntries<com.burner.app.ui.screens.tickets.TicketFilter> getEntries() {
        return null;
    }
}