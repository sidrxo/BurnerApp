package com.burner.app.ui.screens.bookmarks;

import androidx.compose.foundation.layout.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerTypography;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u00000\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\u001a\b\u0010\u0000\u001a\u00020\u0001H\u0003\u001a>\u0010\u0002\u001a\u00020\u00012\f\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u00042\u0012\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\u00010\u00072\u0012\u0010\t\u001a\u000e\u0012\u0004\u0012\u00020\u0005\u0012\u0004\u0012\u00020\u00010\u0007H\u0003\u001aD\u0010\n\u001a\u00020\u00012\u0012\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\u00010\u00072\f\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\u00010\f2\u000e\b\u0002\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u00010\f2\b\b\u0002\u0010\u000e\u001a\u00020\u000fH\u0007\u001a\u0016\u0010\u0010\u001a\u00020\u00012\f\u0010\u0011\u001a\b\u0012\u0004\u0012\u00020\u00010\fH\u0003\u001a\b\u0010\u0012\u001a\u00020\u0001H\u0003\u00a8\u0006\u0013"}, d2 = {"BookmarksHeader", "", "BookmarksList", "events", "", "Lcom/burner/app/data/models/Event;", "onEventClick", "Lkotlin/Function1;", "", "onBookmarkClick", "BookmarksScreen", "onSignInClick", "Lkotlin/Function0;", "onExploreClick", "viewModel", "Lcom/burner/app/ui/screens/bookmarks/BookmarksViewModel;", "EmptyBookmarksState", "onBrowseClick", "LoadingState", "app_debug"})
public final class BookmarksScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void BookmarksScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventClick, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onSignInClick, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onExploreClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.bookmarks.BookmarksViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void BookmarksHeader() {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void LoadingState() {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void EmptyBookmarksState(kotlin.jvm.functions.Function0<kotlin.Unit> onBrowseClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void BookmarksList(java.util.List<com.burner.app.data.models.Event> events, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventClick, kotlin.jvm.functions.Function1<? super com.burner.app.data.models.Event, kotlin.Unit> onBookmarkClick) {
    }
}