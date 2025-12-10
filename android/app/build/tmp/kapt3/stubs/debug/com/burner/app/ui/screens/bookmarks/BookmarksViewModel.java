package com.burner.app.ui.screens.bookmarks;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Bookmark;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.services.AuthService;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00008\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\b\u0007\u0018\u00002\u00020\u0001B\u0017\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006J\b\u0010\u000e\u001a\u00020\u000fH\u0002J\b\u0010\u0010\u001a\u00020\u000fH\u0002J\u000e\u0010\u0011\u001a\u00020\u000f2\u0006\u0010\u0012\u001a\u00020\u0013R\u0014\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\n\u001a\b\u0012\u0004\u0012\u00020\t0\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\r\u00a8\u0006\u0014"}, d2 = {"Lcom/burner/app/ui/screens/bookmarks/BookmarksViewModel;", "Landroidx/lifecycle/ViewModel;", "bookmarkRepository", "Lcom/burner/app/data/repository/BookmarkRepository;", "authService", "Lcom/burner/app/services/AuthService;", "(Lcom/burner/app/data/repository/BookmarkRepository;Lcom/burner/app/services/AuthService;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/bookmarks/BookmarksUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "loadBookmarks", "", "observeAuthState", "removeBookmark", "eventId", "", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class BookmarksViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.BookmarkRepository bookmarkRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.bookmarks.BookmarksUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.bookmarks.BookmarksUiState> uiState = null;
    
    @javax.inject.Inject()
    public BookmarksViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.BookmarkRepository bookmarkRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.services.AuthService authService) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.bookmarks.BookmarksUiState> getUiState() {
        return null;
    }
    
    private final void observeAuthState() {
    }
    
    private final void loadBookmarks() {
    }
    
    public final void removeBookmark(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId) {
    }
}