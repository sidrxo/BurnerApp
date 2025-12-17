package com.burner.app.ui.screens.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.repository.BookmarkRepository
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.data.repository.SearchSortOption
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SearchUiState(
    val searchQuery: String = "",
    val sortOption: SearchSortOption = SearchSortOption.DATE,
    val results: List<Event> = emptyList(),
    val bookmarkedEventIds: Set<String> = emptySet(),
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class SearchViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val bookmarkRepository: BookmarkRepository,
    private val preferencesRepository: PreferencesRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null
    private var userLat: Double? = null
    private var userLon: Double? = null

    init {
        observeBookmarks()
        loadUserLocation()
    }

    private fun loadUserLocation() {
        viewModelScope.launch {
            preferencesRepository.localPreferences.first().let { prefs ->
                userLat = prefs.locationLat
                userLon = prefs.locationLon
            }
        }
    }

    private fun observeBookmarks() {
        viewModelScope.launch {
            bookmarkRepository.getBookmarkedEventIds().collect { ids ->
                _uiState.update { it.copy(bookmarkedEventIds = ids) }
            }
        }
    }

    fun updateSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }

        // Debounced search
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            delay(300)
            performSearch()
        }
    }

    fun setSortOption(option: SearchSortOption) {
        _uiState.update { it.copy(sortOption = option) }
        search()
    }

    fun search() {
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            performSearch()
        }
    }

    private suspend fun performSearch() {
        val state = _uiState.value

        _uiState.update { it.copy(isLoading = true) }

        try {
            val results = eventRepository.searchEvents(
                query = state.searchQuery,
                sortBy = state.sortOption,
                userLat = userLat,
                userLon = userLon
            )

            _uiState.update {
                it.copy(results = results, isLoading = false)
            }
        } catch (e: Exception) {
            _uiState.update {
                it.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun toggleBookmark(event: Event) {
        viewModelScope.launch {
            bookmarkRepository.toggleBookmark(event)
        }
    }
}
