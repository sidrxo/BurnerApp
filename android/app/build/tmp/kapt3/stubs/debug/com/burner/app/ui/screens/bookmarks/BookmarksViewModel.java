package com.burner.app.ui.screens.bookmarks;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Bookmark;
import com.burner.app.data.models.Event;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.services.AuthService;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000P\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010$\n\u0002\u0010\u000e\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u0002\n\u0002\b\b\b\u0007\u0018\u00002\u00020\u0001B\u001f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\u0010\u0010\u0017\u001a\u00020\u00122\u0006\u0010\u0018\u001a\u00020\u000eH\u0002J\b\u0010\u0019\u001a\u00020\u001aH\u0002J\b\u0010\u001b\u001a\u00020\u001aH\u0002J\b\u0010\u001c\u001a\u00020\u001aH\u0002J\u000e\u0010\u001d\u001a\u00020\u001a2\u0006\u0010\u001e\u001a\u00020\u0011J\u000e\u0010\u001f\u001a\u00020\u001a2\u0006\u0010 \u001a\u00020\u0012J\b\u0010!\u001a\u00020\u001aH\u0002R\u0014\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\f\u001a\b\u0012\u0004\u0012\u00020\u000e0\rX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001a\u0010\u000f\u001a\u000e\u0012\u0004\u0012\u00020\u0011\u0012\u0004\u0012\u00020\u00120\u0010X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\u000b0\u0014\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0016\u00a8\u0006\""}, d2 = {"Lcom/burner/app/ui/screens/bookmarks/BookmarksViewModel;", "Landroidx/lifecycle/ViewModel;", "bookmarkRepository", "Lcom/burner/app/data/repository/BookmarkRepository;", "eventRepository", "Lcom/burner/app/data/repository/EventRepository;", "authService", "Lcom/burner/app/services/AuthService;", "(Lcom/burner/app/data/repository/BookmarkRepository;Lcom/burner/app/data/repository/EventRepository;Lcom/burner/app/services/AuthService;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/bookmarks/BookmarksUiState;", "currentBookmarks", "", "Lcom/burner/app/data/models/Bookmark;", "eventsCache", "", "", "Lcom/burner/app/data/models/Event;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "createEventFromBookmark", "bookmark", "loadBookmarks", "", "observeAuthState", "observeEvents", "removeBookmark", "eventId", "toggleBookmark", "event", "updateBookmarkedEvents", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class BookmarksViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.BookmarkRepository bookmarkRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.EventRepository eventRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.bookmarks.BookmarksUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.bookmarks.BookmarksUiState> uiState = null;
    @org.jetbrains.annotations.NotNull()
    private java.util.Map<java.lang.String, com.burner.app.data.models.Event> eventsCache;
    @org.jetbrains.annotations.NotNull()
    private java.util.List<com.burner.app.data.models.Bookmark> currentBookmarks;
    
    @javax.inject.Inject()
    public BookmarksViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.BookmarkRepository bookmarkRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.EventRepository eventRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.services.AuthService authService) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.bookmarks.BookmarksUiState> getUiState() {
        return null;
    }
    
    private final void observeAuthState() {
    }
    
    private final void observeEvents() {
    }
    
    private final void loadBookmarks() {
    }
    
    private final void updateBookmarkedEvents() {
    }
    
    private final com.burner.app.data.models.Event createEventFromBookmark(com.burner.app.data.models.Bookmark bookmark) {
        return null;
    }
    
    public final void removeBookmark(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId) {
    }
    
    public final void toggleBookmark(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.models.Event event) {
    }
}