package com.burner.app.ui.screens.bookmarks;

import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.graphics.Brush;
import androidx.compose.ui.layout.ContentScale;
import androidx.compose.ui.text.font.FontWeight;
import androidx.compose.ui.text.style.TextOverflow;
import com.burner.app.data.models.Bookmark;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;
import java.text.SimpleDateFormat;
import java.util.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u00000\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\u001a,\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\f\u0010\u0004\u001a\b\u0012\u0004\u0012\u00020\u00010\u00052\f\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00010\u0005H\u0003\u001a\u0010\u0010\u0007\u001a\u00020\u00012\u0006\u0010\b\u001a\u00020\tH\u0003\u001a4\u0010\n\u001a\u00020\u00012\u0012\u0010\u000b\u001a\u000e\u0012\u0004\u0012\u00020\r\u0012\u0004\u0012\u00020\u00010\f2\f\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u00010\u00052\b\b\u0002\u0010\u000f\u001a\u00020\u0010H\u0007\u00a8\u0006\u0011"}, d2 = {"BookmarkCard", "", "bookmark", "Lcom/burner/app/data/models/Bookmark;", "onClick", "Lkotlin/Function0;", "onRemove", "BookmarkDateChip", "date", "Ljava/util/Date;", "BookmarksScreen", "onEventClick", "Lkotlin/Function1;", "", "onSignInClick", "viewModel", "Lcom/burner/app/ui/screens/bookmarks/BookmarksViewModel;", "app_debug"})
public final class BookmarksScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void BookmarksScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventClick, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onSignInClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.bookmarks.BookmarksViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void BookmarkCard(com.burner.app.data.models.Bookmark bookmark, kotlin.jvm.functions.Function0<kotlin.Unit> onClick, kotlin.jvm.functions.Function0<kotlin.Unit> onRemove) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void BookmarkDateChip(java.util.Date date) {
    }
}