package com.burner.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.repository.BookmarkRepository
import com.burner.app.data.repository.EventRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EventDetailUiState(
    val event: Event? = null,
    val isBookmarked: Boolean = false,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class EventDetailViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val bookmarkRepository: BookmarkRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(EventDetailUiState())
    val uiState: StateFlow<EventDetailUiState> = _uiState.asStateFlow()

    private var currentEventId: String? = null

    fun loadEvent(eventId: String) {
        currentEventId = eventId

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            // Observe event changes
            eventRepository.getEventFlow(eventId).collect { event ->
                _uiState.update {
                    it.copy(event = event, isLoading = false)
                }
            }
        }

        // Check bookmark status
        viewModelScope.launch {
            val isBookmarked = bookmarkRepository.isBookmarked(eventId)
            _uiState.update { it.copy(isBookmarked = isBookmarked) }
        }
    }

    fun toggleBookmark() {
        val event = _uiState.value.event ?: return

        viewModelScope.launch {
            val result = bookmarkRepository.toggleBookmark(event)
            result.onSuccess { isNowBookmarked ->
                _uiState.update { it.copy(isBookmarked = isNowBookmarked) }
            }
        }
    }
}
