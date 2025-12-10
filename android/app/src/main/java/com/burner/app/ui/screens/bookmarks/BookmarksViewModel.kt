package com.burner.app.ui.screens.bookmarks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Bookmark
import com.burner.app.data.repository.BookmarkRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class BookmarksUiState(
    val bookmarks: List<Bookmark> = emptyList(),
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class BookmarksViewModel @Inject constructor(
    private val bookmarkRepository: BookmarkRepository,
    private val authService: AuthService
) : ViewModel() {

    private val _uiState = MutableStateFlow(BookmarksUiState())
    val uiState: StateFlow<BookmarksUiState> = _uiState.asStateFlow()

    init {
        observeAuthState()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                val isAuthenticated = user != null
                _uiState.update { it.copy(isAuthenticated = isAuthenticated) }

                if (isAuthenticated) {
                    loadBookmarks()
                } else {
                    _uiState.update { it.copy(bookmarks = emptyList(), isLoading = false) }
                }
            }
        }
    }

    private fun loadBookmarks() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            bookmarkRepository.getUserBookmarks().collect { bookmarks ->
                _uiState.update {
                    it.copy(bookmarks = bookmarks, isLoading = false)
                }
            }
        }
    }

    fun removeBookmark(eventId: String) {
        viewModelScope.launch {
            bookmarkRepository.removeBookmark(eventId)
        }
    }
}
