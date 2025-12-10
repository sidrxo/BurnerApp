package com.burner.app.ui.screens.search;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.PreferencesRepository;
import com.burner.app.data.repository.SearchSortOption;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\\\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0006\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0006\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\b\u0007\u0018\u00002\u00020\u0001B\u001f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\b\u0010\u0016\u001a\u00020\u0017H\u0002J\b\u0010\u0018\u001a\u00020\u0017H\u0002J\u000e\u0010\u0019\u001a\u00020\u0017H\u0082@\u00a2\u0006\u0002\u0010\u001aJ\u0006\u0010\u001b\u001a\u00020\u0017J\u000e\u0010\u001c\u001a\u00020\u00172\u0006\u0010\u001d\u001a\u00020\u001eJ\u000e\u0010\u001f\u001a\u00020\u00172\u0006\u0010 \u001a\u00020!J\u000e\u0010\"\u001a\u00020\u00172\u0006\u0010#\u001a\u00020$R\u0014\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010\f\u001a\u0004\u0018\u00010\rX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u000b0\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0012\u0010\u0012\u001a\u0004\u0018\u00010\u0013X\u0082\u000e\u00a2\u0006\u0004\n\u0002\u0010\u0014R\u0012\u0010\u0015\u001a\u0004\u0018\u00010\u0013X\u0082\u000e\u00a2\u0006\u0004\n\u0002\u0010\u0014\u00a8\u0006%"}, d2 = {"Lcom/burner/app/ui/screens/search/SearchViewModel;", "Landroidx/lifecycle/ViewModel;", "eventRepository", "Lcom/burner/app/data/repository/EventRepository;", "bookmarkRepository", "Lcom/burner/app/data/repository/BookmarkRepository;", "preferencesRepository", "Lcom/burner/app/data/repository/PreferencesRepository;", "(Lcom/burner/app/data/repository/EventRepository;Lcom/burner/app/data/repository/BookmarkRepository;Lcom/burner/app/data/repository/PreferencesRepository;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/search/SearchUiState;", "searchJob", "Lkotlinx/coroutines/Job;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "userLat", "", "Ljava/lang/Double;", "userLon", "loadUserLocation", "", "observeBookmarks", "performSearch", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "search", "setSortOption", "option", "Lcom/burner/app/data/repository/SearchSortOption;", "toggleBookmark", "event", "Lcom/burner/app/data/models/Event;", "updateSearchQuery", "query", "", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class SearchViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.EventRepository eventRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.BookmarkRepository bookmarkRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.PreferencesRepository preferencesRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.search.SearchUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.search.SearchUiState> uiState = null;
    @org.jetbrains.annotations.Nullable()
    private kotlinx.coroutines.Job searchJob;
    @org.jetbrains.annotations.Nullable()
    private java.lang.Double userLat;
    @org.jetbrains.annotations.Nullable()
    private java.lang.Double userLon;
    
    @javax.inject.Inject()
    public SearchViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.EventRepository eventRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.BookmarkRepository bookmarkRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.PreferencesRepository preferencesRepository) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.search.SearchUiState> getUiState() {
        return null;
    }
    
    private final void loadUserLocation() {
    }
    
    private final void observeBookmarks() {
    }
    
    public final void updateSearchQuery(@org.jetbrains.annotations.NotNull()
    java.lang.String query) {
    }
    
    public final void setSortOption(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.SearchSortOption option) {
    }
    
    public final void search() {
    }
    
    private final java.lang.Object performSearch(kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    public final void toggleBookmark(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.Event event) {
    }
}