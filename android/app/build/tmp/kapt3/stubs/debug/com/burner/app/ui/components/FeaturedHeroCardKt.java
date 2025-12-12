package com.burner.app.ui.components;

import androidx.compose.animation.core.Spring;
import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.runtime.Composable;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.graphics.Brush;
import androidx.compose.ui.layout.ContentScale;
import androidx.compose.ui.text.font.FontWeight;
import androidx.compose.ui.text.style.TextOverflow;
import com.burner.app.data.models.Event;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;
import java.text.SimpleDateFormat;
import java.util.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u00002\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\u001aJ\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\u0016\b\u0002\u0010\u0006\u001a\u0010\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u0001\u0018\u00010\u00072\f\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00010\t2\b\b\u0002\u0010\n\u001a\u00020\u000bH\u0007\u001a\u0010\u0010\f\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fH\u0002\u00a8\u0006\u0010"}, d2 = {"FeaturedHeroCard", "", "event", "Lcom/burner/app/data/models/Event;", "isBookmarked", "", "onBookmarkClick", "Lkotlin/Function1;", "onClick", "Lkotlin/Function0;", "modifier", "Landroidx/compose/ui/Modifier;", "formatDateLong", "", "date", "Ljava/util/Date;", "app_debug"})
public final class FeaturedHeroCardKt {
    
    /**
     * Featured Hero Card matching iOS FeaturedHeroCard
     * Full-width card with image, blur effect, and event details
     */
    @androidx.compose.runtime.Composable()
    public static final void FeaturedHeroCard(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.Event event, boolean isBookmarked, @org.jetbrains.annotations.Nullable()
    kotlin.jvm.functions.Function1<? super com.burner.app.data.models.Event, kotlin.Unit> onBookmarkClick, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onClick, @org.jetbrains.annotations.NotNull()
    androidx.compose.ui.Modifier modifier) {
    }
    
    private static final java.lang.String formatDateLong(java.util.Date date) {
        return null;
    }
}