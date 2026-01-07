package com.burner.app.ui.screens.explore

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.Event
import com.burner.app.data.repository.BookmarkRepository
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.data.repository.TagRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date
import javax.inject.Inject
import kotlin.random.Random

data class ExploreUiState(
    val allEvents: List<Event> = emptyList(),
    val featuredEvents: List<Event> = emptyList(),
    val popularEvents: List<Event> = emptyList(),
    val thisWeekEvents: List<Event> = emptyList(),
    val nearbyEvents: List<Event> = emptyList(),
    val genres: List<String> = emptyList(),
    val bookmarkedEventIds: Set<String> = emptySet(),
    val userLat: Double? = null,
    val userLon: Double? = null,
    val isLoading: Boolean = true,
    val error: String? = null
)

@HiltViewModel
class ExploreViewModel @Inject constructor(
    private val eventRepository: EventRepository,
    private val bookmarkRepository: BookmarkRepository,
    private val preferencesRepository: PreferencesRepository,
    private val tagRepository: TagRepository,
    private val authService: AuthService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ExploreUiState())
    val uiState: StateFlow<ExploreUiState> = _uiState.asStateFlow()

    private var bookmarksJob: Job? = null

    init {
        observeEvents()
        observeTags()
        loadUserLocation()
        observeAuthState()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                if (user != null) {
                    // FIX: Call the new public function
                    loadBookmarks()
                } else {
                    bookmarksJob?.cancel()
                    _uiState.update { it.copy(bookmarkedEventIds = emptySet()) }
                }
            }
        }
    }

    private fun observeEvents() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            eventRepository.allEvents.collect { events ->
                Log.d("ExploreViewModel", "Received ${events.size} events")

                val now = Date()
                val calendar = Calendar.getInstance()
                calendar.time = now
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.add(Calendar.DAY_OF_YEAR, 7)
                val endOfWeek = calendar.time

                val dayOfYear = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
                val featured = events
                    .filter { it.isFeatured && (it.startDate?.after(now) == true) }
                    .shuffled(Random(dayOfYear.toLong()))

                val thisWeekEventIds = mutableSetOf<String>()
                val thisWeek = events
                    .filter { event ->
                        val startTime = event.startDate
                        !event.isFeatured &&
                                startTime != null &&
                                startTime.after(now) &&
                                startTime.before(endOfWeek)
                    }
                    .sortedBy { it.startDate }
                    .take(5)
                    .also { list -> list.forEach { it.id?.let { id -> thisWeekEventIds.add(id) } } }

                val popular = events
                    .filter { event ->
                        val startTime = event.startDate
                        !event.isFeatured &&
                                startTime != null &&
                                startTime.after(now) &&
                                !thisWeekEventIds.contains(event.id)
                    }
                    .sortedByDescending { event ->
                        val maxTickets = event.maxTickets.coerceAtLeast(1)
                        event.ticketsSold.toDouble() / maxTickets.toDouble()
                    }
                    .take(5)

                val currentState = _uiState.value
                val nearby = if (currentState.userLat != null && currentState.userLon != null) {
                    computeNearbyEvents(events, currentState.userLat, currentState.userLon, now)
                } else {
                    emptyList()
                }

                _uiState.update {
                    it.copy(
                        allEvents = events,
                        featuredEvents = featured,
                        popularEvents = popular,
                        thisWeekEvents = thisWeek,
                        nearbyEvents = nearby,
                        isLoading = false,
                        error = null
                    )
                }
            }
        }
    }

    private fun loadUserLocation() {
        viewModelScope.launch {
            preferencesRepository.localPreferences.collect { prefs ->
                _uiState.update { state ->
                    val nearby = if (prefs.locationLat != null && prefs.locationLon != null && state.allEvents.isNotEmpty()) {
                        computeNearbyEvents(state.allEvents, prefs.locationLat, prefs.locationLon, Date())
                    } else {
                        state.nearbyEvents
                    }
                    state.copy(
                        userLat = prefs.locationLat,
                        userLon = prefs.locationLon,
                        nearbyEvents = nearby
                    )
                }
            }
        }
    }

    private fun computeNearbyEvents(
        events: List<Event>,
        userLat: Double,
        userLon: Double,
        now: Date,
        maxDistanceKm: Double = 80.0
    ): List<Event> {
        return events
            .filter { event ->
                val startTime = event.startDate
                !event.isFeatured &&
                        startTime != null &&
                        startTime.after(now) &&
                        event.latitude != null && event.longitude != null
            }
            .mapNotNull { event ->
                val distance = event.distanceFrom(userLat, userLon)
                if (distance != null && distance <= maxDistanceKm) {
                    Pair(event, distance)
                } else {
                    null
                }
            }
            .sortedBy { it.second }
            .take(5)
            .map { it.first }
    }

    // FIX: Changed from private 'observeBookmarks' to public 'loadBookmarks'
    fun loadBookmarks() {
        // Cancel existing job to avoid duplicate listeners or stale states
        bookmarksJob?.cancel()

        bookmarksJob = viewModelScope.launch {
            // This triggers the repository to emit the current list immediately
            bookmarkRepository.getBookmarkedEventIds().collect { ids ->
                _uiState.update { it.copy(bookmarkedEventIds = ids) }
            }
        }
    }

    private fun observeTags() {
        viewModelScope.launch {
            tagRepository.allTags.collect { tags ->
                val genreNames = tags.map { it.name }
                _uiState.update { it.copy(genres = genreNames) }
            }
        }
    }

    fun toggleBookmark(event: Event) {
        val eventId = event.id ?: return
        val currentBookmarks = _uiState.value.bookmarkedEventIds
        val isCurrentlyBookmarked = currentBookmarks.contains(eventId)

        // Optimistic Update
        val newBookmarks = if (isCurrentlyBookmarked) {
            currentBookmarks - eventId
        } else {
            currentBookmarks + eventId
        }

        _uiState.update { it.copy(bookmarkedEventIds = newBookmarks) }

        viewModelScope.launch {
            val result = bookmarkRepository.toggleBookmark(event)
            if (result.isFailure) {
                _uiState.update { it.copy(bookmarkedEventIds = currentBookmarks) }
                Log.e("ExploreViewModel", "Failed to toggle bookmark", result.exceptionOrNull())
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            // Note: Flows handle data refresh automatically, but this loading state gives visual feedback
        }
    }

    fun formatDistance(distanceKm: Double): String {
        val miles = distanceKm * 0.621371
        return if (miles < 0.1) {
            val feet = distanceKm * 3280.84
            "${feet.toInt()}ft"
        } else {
            "${miles.toInt()}mi"
        }
    }
}