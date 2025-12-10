package com.burner.app.ui.screens.search;

import androidx.compose.foundation.layout.*;
import androidx.compose.foundation.text.KeyboardOptions;
import androidx.compose.material.icons.Icons;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.focus.FocusRequester;
import androidx.compose.ui.graphics.SolidColor;
import androidx.compose.ui.text.input.ImeAction;
import androidx.compose.ui.text.style.TextAlign;
import com.burner.app.data.repository.SearchSortOption;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerTypography;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000R\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010 \n\u0000\n\u0002\u0010\"\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\u001a8\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\u0012\u0010\u0004\u001a\u000e\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u00010\u00052\u0012\u0010\u0007\u001a\u000e\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\u00010\u0005H\u0003\u001a\b\u0010\t\u001a\u00020\u0001H\u0003\u001a&\u0010\n\u001a\u00020\u00012\u0006\u0010\u000b\u001a\u00020\u00062\u0006\u0010\f\u001a\u00020\r2\f\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u00010\u000fH\u0003\u001a$\u0010\u0010\u001a\u00020\u00012\u0006\u0010\u0011\u001a\u00020\u00122\u0012\u0010\u0013\u001a\u000e\u0012\u0004\u0012\u00020\u0012\u0012\u0004\u0012\u00020\u00010\u0005H\u0003\u001a\b\u0010\u0014\u001a\u00020\u0001H\u0003\u001aL\u0010\u0015\u001a\u00020\u00012\f\u0010\u0016\u001a\b\u0012\u0004\u0012\u00020\b0\u00172\f\u0010\u0018\u001a\b\u0012\u0004\u0012\u00020\u00060\u00192\u0012\u0010\u0004\u001a\u000e\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u00010\u00052\u0012\u0010\u0007\u001a\u000e\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\u00010\u0005H\u0003\u001aP\u0010\u001a\u001a\u00020\u00012\u0006\u0010\u001b\u001a\u00020\u00062\u0012\u0010\u001c\u001a\u000e\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u00010\u00052\f\u0010\u001d\u001a\b\u0012\u0004\u0012\u00020\u00010\u000f2\f\u0010\u001e\u001a\b\u0012\u0004\u0012\u00020\u00010\u000f2\u0006\u0010\u001f\u001a\u00020\r2\u0006\u0010 \u001a\u00020!H\u0003\u001a\b\u0010\"\u001a\u00020\u0001H\u0003\u001a&\u0010#\u001a\u00020\u00012\u0012\u0010\u0004\u001a\u000e\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u00010\u00052\b\b\u0002\u0010$\u001a\u00020%H\u0007\u00a8\u0006&"}, d2 = {"ContentSection", "", "uiState", "Lcom/burner/app/ui/screens/search/SearchUiState;", "onEventClick", "Lkotlin/Function1;", "", "onBookmarkClick", "Lcom/burner/app/data/models/Event;", "EmptySearchView", "FilterButton", "text", "isSelected", "", "onClick", "Lkotlin/Function0;", "FilterSection", "selectedOption", "Lcom/burner/app/data/repository/SearchSortOption;", "onOptionSelected", "LoadingStateView", "ResultsList", "events", "", "bookmarkedIds", "", "SearchFieldSection", "value", "onValueChange", "onSearch", "onClear", "isSearching", "focusRequester", "Landroidx/compose/ui/focus/FocusRequester;", "SearchHeader", "SearchScreen", "viewModel", "Lcom/burner/app/ui/screens/search/SearchViewModel;", "app_debug"})
public final class SearchScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void SearchScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.search.SearchViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void SearchHeader() {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void SearchFieldSection(java.lang.String value, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onValueChange, kotlin.jvm.functions.Function0<kotlin.Unit> onSearch, kotlin.jvm.functions.Function0<kotlin.Unit> onClear, boolean isSearching, androidx.compose.ui.focus.FocusRequester focusRequester) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void FilterSection(com.burner.app.data.repository.SearchSortOption selectedOption, kotlin.jvm.functions.Function1<? super com.burner.app.data.repository.SearchSortOption, kotlin.Unit> onOptionSelected) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void FilterButton(java.lang.String text, boolean isSelected, kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void ContentSection(com.burner.app.ui.screens.search.SearchUiState uiState, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventClick, kotlin.jvm.functions.Function1<? super com.burner.app.data.models.Event, kotlin.Unit> onBookmarkClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void LoadingStateView() {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void EmptySearchView() {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void ResultsList(java.util.List<com.burner.app.data.models.Event> events, java.util.Set<java.lang.String> bookmarkedIds, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventClick, kotlin.jvm.functions.Function1<? super com.burner.app.data.models.Event, kotlin.Unit> onBookmarkClick) {
    }
}