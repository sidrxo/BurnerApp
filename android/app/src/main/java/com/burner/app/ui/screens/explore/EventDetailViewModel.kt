package com.burner.app.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.repository.BookmarkRepository
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.TicketRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date
import javax.inject.Inject

data class EventDetailUiState(
    val event: Event? = null,
    val isBookmarked: Boolean = false,
    val userHasTicket: Boolean = false,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class EventDetailViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val bookmarkRepository: BookmarkRepository,
    private val ticketRepository: TicketRepository
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

        // Check user ticket status
        checkUserTicketStatus(eventId)
    }

    private fun checkUserTicketStatus(eventId: String) {
        viewModelScope.launch {
            ticketRepository.getUserTickets().collect { tickets ->
                val hasTicket = tickets.any { it.eventId == eventId && it.isActive }
                _uiState.update { it.copy(userHasTicket = hasTicket) }
            }
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

    // Compute available tickets
    fun availableTickets(): Int {
        val event = _uiState.value.event ?: return 0
        return maxOf(0, event.maxTickets - event.ticketsSold)
    }

    // Check if event has started (matching iOS)
    fun hasEventStarted(): Boolean {
        val event = _uiState.value.event ?: return false
        val startTime = event.startDate ?: return false
        return Date() >= startTime
    }

    // Check if event is past (matching iOS - 6 hours after start or past end time)
    fun isEventPast(): Boolean {
        val event = _uiState.value.event ?: return false

        event.endDate?.let { endTime ->
            if (Date() > endTime) return true
        }

        val startTime = event.startDate ?: return false
        val calendar = Calendar.getInstance()
        calendar.time = startTime
        calendar.add(Calendar.HOUR, 6)
        val sixHoursAfterStart = calendar.time
        return Date() > sixHoursAfterStart
    }

    // Get button text based on state (matching iOS 5-state system)
    fun getButtonText(): String {
        return when {
            isEventPast() -> "EVENT PAST"
            hasEventStarted() -> "EVENT STARTED"
            _uiState.value.userHasTicket -> "TICKET PURCHASED"
            availableTickets() > 0 -> "GET TICKET"
            else -> "SOLD OUT"
        }
    }

    // Check if button should be disabled
    fun isButtonDisabled(): Boolean {
        return isEventPast() || hasEventStarted() || _uiState.value.userHasTicket || availableTickets() == 0
    }

    // Get button style (for future implementation of dimmed styles)
    fun getButtonStyle(): ButtonStyle {
        return when {
            availableTickets() > 0 && !isEventPast() && !hasEventStarted() && !_uiState.value.userHasTicket -> ButtonStyle.PRIMARY
            availableTickets() == 0 && !isEventPast() && !hasEventStarted() -> ButtonStyle.DIMMED_RED
            _uiState.value.userHasTicket && !isEventPast() && !hasEventStarted() -> ButtonStyle.DIMMED_WHITE
            else -> ButtonStyle.DIMMED_GRAY
        }
    }
}

enum class ButtonStyle {
    PRIMARY,          // Solid white, enabled
    DIMMED_RED,      // Dimmed with red outline (sold out)
    DIMMED_WHITE,    // Dimmed with white outline (purchased)
    DIMMED_GRAY      // Dimmed with gray outline (past/started)
}
