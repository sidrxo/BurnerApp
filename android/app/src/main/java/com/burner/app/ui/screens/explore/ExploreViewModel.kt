package com.burner.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.repository.BookmarkRepository
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.PreferencesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ExploreUiState(
    val featuredEvents: List<Event> = emptyList(),
    val thisWeekEvents: List<Event> = emptyList(),
    val nearbyEvents: List<Event> = emptyList(),
    val bookmarkedEventIds: Set<String> = emptySet(),
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class ExploreViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val bookmarkRepository: BookmarkRepository,
    private val preferencesRepository: PreferencesRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ExploreUiState())
    val uiState: StateFlow<ExploreUiState> = _uiState.asStateFlow()

    init {
        loadData()
        observeBookmarks()
    }

    private fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            try {
                // Load featured events
                val featured = eventRepository.getFeaturedEvents()
                _uiState.update { it.copy(featuredEvents = featured) }

                // Load this week events
                val thisWeek = eventRepository.getThisWeekEvents()
                _uiState.update { it.copy(thisWeekEvents = thisWeek) }

                // Load nearby events based on user location
                preferencesRepository.localPreferences.first().let { prefs ->
                    if (prefs.locationLat != null && prefs.locationLon != null) {
                        val nearby = eventRepository.getNearbyEvents(
                            prefs.locationLat,
                            prefs.locationLon
                        )
                        _uiState.update { it.copy(nearbyEvents = nearby) }
                    }
                }

                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = e.message)
                }
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

    fun toggleBookmark(event: Event) {
        viewModelScope.launch {
            bookmarkRepository.toggleBookmark(event)
        }
    }

    fun refresh() {
        loadData()
    }
}
