package com.burner.app.ui.screens.tickets;

import android.graphics.Bitmap;
import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.material.icons.filled.*;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.text.style.TextAlign;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.qrcode.QRCodeWriter;
import com.burner.app.data.models.Ticket;
import com.burner.app.data.models.TicketStatus;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;
import java.text.SimpleDateFormat;
import java.util.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000@\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\u001a\"\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u0005H\u0003\u00f8\u0001\u0000\u00a2\u0006\u0004\b\u0006\u0010\u0007\u001a(\u0010\b\u001a\u00020\u00012\u0006\u0010\t\u001a\u00020\u00032\f\u0010\n\u001a\b\u0012\u0004\u0012\u00020\u00010\u000b2\b\b\u0002\u0010\f\u001a\u00020\rH\u0007\u001a \u0010\u000e\u001a\u00020\u00012\u0006\u0010\u000f\u001a\u00020\u00102\u0006\u0010\u0011\u001a\u00020\u00032\u0006\u0010\u0012\u001a\u00020\u0003H\u0003\u001a\u0010\u0010\u0013\u001a\u00020\u00012\u0006\u0010\u0014\u001a\u00020\u0003H\u0003\u001a\u0010\u0010\u0015\u001a\u00020\u00032\u0006\u0010\u0016\u001a\u00020\u0017H\u0002\u001a\u0010\u0010\u0018\u001a\u00020\u00032\u0006\u0010\u0016\u001a\u00020\u0017H\u0002\u001a\u0010\u0010\u0019\u001a\u00020\u00032\u0006\u0010\u0016\u001a\u00020\u0017H\u0002\u001a\u001a\u0010\u001a\u001a\u0004\u0018\u00010\u001b2\u0006\u0010\u001c\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u001dH\u0002\u0082\u0002\u0007\n\u0005\b\u00a1\u001e0\u0001\u00a8\u0006\u001e"}, d2 = {"QRCodeImage", "", "data", "", "size", "Landroidx/compose/ui/unit/Dp;", "QRCodeImage-3ABfNKs", "(Ljava/lang/String;F)V", "TicketDetailScreen", "ticketId", "onBackClick", "Lkotlin/Function0;", "viewModel", "Lcom/burner/app/ui/screens/tickets/TicketDetailViewModel;", "TicketInfoRow", "icon", "Landroidx/compose/ui/graphics/vector/ImageVector;", "label", "value", "TicketStatusChip", "status", "formatDateDetailed", "date", "Ljava/util/Date;", "formatFullDate", "formatTime", "generateQRCode", "Landroid/graphics/Bitmap;", "content", "", "app_debug"})
public final class TicketDetailScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void TicketDetailScreen(@org.jetbrains.annotations.NotNull()
    java.lang.String ticketId, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onBackClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.tickets.TicketDetailViewModel viewModel) {
    }
    
    private static final android.graphics.Bitmap generateQRCode(java.lang.String content, int size) {
        return null;
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TicketStatusChip(java.lang.String status) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TicketInfoRow(androidx.compose.ui.graphics.vector.ImageVector icon, java.lang.String label, java.lang.String value) {
    }
    
    private static final java.lang.String formatFullDate(java.util.Date date) {
        return null;
    }
    
    private static final java.lang.String formatDateDetailed(java.util.Date date) {
        return null;
    }
    
    private static final java.lang.String formatTime(java.util.Date date) {
        return null;
    }
}