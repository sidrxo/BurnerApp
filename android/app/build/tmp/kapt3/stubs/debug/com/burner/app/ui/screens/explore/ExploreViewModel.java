package com.burner.app.ui.screens.explore;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.PreferencesRepository;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000>\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\b\u0007\u0018\u00002\u00020\u0001B\u001f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\b\u0010\u0010\u001a\u00020\u0011H\u0002J\b\u0010\u0012\u001a\u00020\u0011H\u0002J\u0006\u0010\u0013\u001a\u00020\u0011J\u000e\u0010\u0014\u001a\u00020\u00112\u0006\u0010\u0015\u001a\u00020\u0016R\u0014\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\f\u001a\b\u0012\u0004\u0012\u00020\u000b0\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000f\u00a8\u0006\u0017"}, d2 = {"Lcom/burner/app/ui/screens/explore/ExploreViewModel;", "Landroidx/lifecycle/ViewModel;", "eventRepository", "Lcom/burner/app/data/repository/EventRepository;", "bookmarkRepository", "Lcom/burner/app/data/repository/BookmarkRepository;", "preferencesRepository", "Lcom/burner/app/data/repository/PreferencesRepository;", "(Lcom/burner/app/data/repository/EventRepository;Lcom/burner/app/data/repository/BookmarkRepository;Lcom/burner/app/data/repository/PreferencesRepository;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/explore/ExploreUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "loadData", "", "observeBookmarks", "refresh", "toggleBookmark", "event", "Lcom/burner/app/data/models/Event;", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class ExploreViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.EventRepository eventRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.BookmarkRepository bookmarkRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.PreferencesRepository preferencesRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.explore.ExploreUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.explore.ExploreUiState> uiState = null;
    
    @javax.inject.Inject()
    public ExploreViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.EventRepository eventRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.BookmarkRepository bookmarkRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.PreferencesRepository preferencesRepository) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.explore.ExploreUiState> getUiState() {
        return null;
    }
    
    private final void loadData() {
    }
    
    private final void observeBookmarks() {
    }
    
    public final void toggleBookmark(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.Event event) {
    }
    
    public final void refresh() {
    }
}