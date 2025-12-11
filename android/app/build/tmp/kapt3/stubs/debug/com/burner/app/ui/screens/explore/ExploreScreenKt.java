package com.burner.app.ui.screens.explore;

import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.material3.ExperimentalMaterial3Api;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.text.font.FontWeight;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000:\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010 \n\u0002\b\u0002\u001a,\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\u0010\b\u0002\u0010\u0006\u001a\n\u0012\u0004\u0012\u00020\u0001\u0018\u00010\u0007H\u0003\u001a*\u0010\b\u001a\u00020\u00012\u0006\u0010\t\u001a\u00020\n2\u000e\u0010\u000b\u001a\n\u0012\u0004\u0012\u00020\u0001\u0018\u00010\u00072\b\b\u0002\u0010\u0004\u001a\u00020\u0005H\u0003\u001a8\u0010\f\u001a\u00020\u00012\u0012\u0010\r\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u000e2\u0010\b\u0002\u0010\u000b\u001a\n\u0012\u0004\u0012\u00020\u0001\u0018\u00010\u00072\b\b\u0002\u0010\u000f\u001a\u00020\u0010H\u0007\u001a(\u0010\u0011\u001a\u00020\u00012\u0006\u0010\u0012\u001a\u00020\u00032\f\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\u00010\u00072\b\b\u0002\u0010\u0004\u001a\u00020\u0005H\u0003\u001a4\u0010\u0014\u001a\u00020\u00012\f\u0010\u0015\u001a\b\u0012\u0004\u0012\u00020\u00030\u00162\u0012\u0010\u0017\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u000e2\b\b\u0002\u0010\u0004\u001a\u00020\u0005H\u0003\u00a8\u0006\u0018"}, d2 = {"EventSectionHeader", "", "title", "", "modifier", "Landroidx/compose/ui/Modifier;", "onViewAll", "Lkotlin/Function0;", "ExploreHeader", "hasLocation", "", "onLocationClick", "ExploreScreen", "onEventClick", "Lkotlin/Function1;", "viewModel", "Lcom/burner/app/ui/screens/explore/ExploreViewModel;", "GenreCard", "genreName", "onClick", "GenreCardsRow", "genres", "", "onGenreClick", "app_debug"})
public final class ExploreScreenKt {
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable()
    public static final void ExploreScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventClick, @org.jetbrains.annotations.Nullable()
    kotlin.jvm.functions.Function0<kotlin.Unit> onLocationClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.explore.ExploreViewModel viewModel) {
    }
    
    /**
     * Explore Header matching iOS ExploreView header
     */
    @androidx.compose.runtime.Composable()
    private static final void ExploreHeader(boolean hasLocation, kotlin.jvm.functions.Function0<kotlin.Unit> onLocationClick, androidx.compose.ui.Modifier modifier) {
    }
    
    /**
     * Event Section Header matching iOS style
     */
    @androidx.compose.runtime.Composable()
    private static final void EventSectionHeader(java.lang.String title, androidx.compose.ui.Modifier modifier, kotlin.jvm.functions.Function0<kotlin.Unit> onViewAll) {
    }
    
    /**
     * Genre Cards Row matching iOS GenreCardsScrollRow
     */
    @androidx.compose.runtime.Composable()
    private static final void GenreCardsRow(java.util.List<java.lang.String> genres, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onGenreClick, androidx.compose.ui.Modifier modifier) {
    }
    
    /**
     * Genre Card matching iOS GenreCard
     */
    @androidx.compose.runtime.Composable()
    private static final void GenreCard(java.lang.String genreName, kotlin.jvm.functions.Function0<kotlin.Unit> onClick, androidx.compose.ui.Modifier modifier) {
    }
}