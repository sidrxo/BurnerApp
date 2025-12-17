package com.burner.app.ui.screens.bookmarks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Bookmark
import com.burner.app.data.models.Event
import com.burner.app.data.repository.BookmarkRepository
import com.burner.app.data.repository.EventRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class BookmarksUiState(
    val bookmarkedEvents: List<Event> = emptyList(),
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class BookmarksViewModel @Inject constructor(
    private val bookmarkRepository: BookmarkRepository,
    private val eventRepository: EventRepository,
    private val authService: AuthService
) : ViewModel() {

    private val _uiState = MutableStateFlow(BookmarksUiState())
    val uiState: StateFlow<BookmarksUiState> = _uiState.asStateFlow()

    private var eventsCache: Map<String, Event> = emptyMap()
    private var currentBookmarks: List<Bookmark> = emptyList()

    init {
        observeAuthState()
        observeEvents()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                val isAuthenticated = user != null
                _uiState.update { it.copy(isAuthenticated = isAuthenticated) }

                if (isAuthenticated) {
                    loadBookmarks()
                } else {
                    _uiState.update { it.copy(bookmarkedEvents = emptyList(), isLoading = false) }
                }
            }
        }
    }

    private fun observeEvents() {
        viewModelScope.launch {
            eventRepository.allEvents.collect { events ->
                eventsCache = events.associateBy { it.id ?: "" }
                updateBookmarkedEvents()
            }
        }
    }

    private fun loadBookmarks() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            bookmarkRepository.getUserBookmarks().collect { bookmarks ->
                currentBookmarks = bookmarks
                updateBookmarkedEvents()
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    private fun updateBookmarkedEvents() {
        val events = currentBookmarks.mapNotNull { bookmark ->
            // Try to get full event from cache, or create from bookmark data
            eventsCache[bookmark.eventId] ?: createEventFromBookmark(bookmark)
        }
        _uiState.update { it.copy(bookmarkedEvents = events) }
    }

    private fun createEventFromBookmark(bookmark: Bookmark): Event {
        return Event(
            id = bookmark.eventId,
            name = bookmark.eventName,
            venue = bookmark.eventVenue,
            startTime = bookmark.startTime,
            price = bookmark.eventPrice,
            maxTickets = 100,
            ticketsSold = 0,
            imageUrl = bookmark.eventImageUrl,
            isFeatured = false,
            description = null
        )
    }

    fun removeBookmark(eventId: String) {
        viewModelScope.launch {
            bookmarkRepository.removeBookmark(eventId)
        }
    }

    fun toggleBookmark(event: Event) {
        viewModelScope.launch {
            bookmarkRepository.toggleBookmark(event)
        }
    }
}
