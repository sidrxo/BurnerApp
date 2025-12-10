package com.burner.app.ui.screens.onboarding

import android.annotation.SuppressLint
import android.content.Context
import android.location.Geocoder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.burner.app.data.models.Tag
import com.burner.app.data.repository.EventRepository
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.data.repository.TagRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.*
import javax.inject.Inject

data class OnboardingUiState(
    val currentStep: OnboardingStep = OnboardingStep.WELCOME,
    val locationName: String? = null,
    val locationLat: Double? = null,
    val locationLon: Double? = null,
    val isLoadingLocation: Boolean = false,
    val availableGenres: List<String> = Tag.defaultGenres.map { it.name },
    val selectedGenres: Set<String> = emptySet(),
    val notificationsEnabled: Boolean = false,
    val eventImageUrls: List<String> = emptyList()
) {
    // Progress step (0-2) for Location(1), Genres(2), Notifications(3)
    val progressStep: Int
        get() = when (currentStep) {
            OnboardingStep.WELCOME -> 0
            OnboardingStep.LOCATION -> 0
            OnboardingStep.GENRES -> 1
            OnboardingStep.NOTIFICATIONS -> 2
            OnboardingStep.COMPLETE -> 2
        }

    // Total flow steps (excluding welcome and complete)
    val totalFlowSteps: Int = 3

    // Whether to show back button
    val showBackButton: Boolean
        get() = currentStep != OnboardingStep.WELCOME && currentStep != OnboardingStep.COMPLETE

    // Whether to show skip button
    val showSkipButton: Boolean
        get() = currentStep in listOf(OnboardingStep.LOCATION, OnboardingStep.GENRES, OnboardingStep.NOTIFICATIONS)
}

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val preferencesRepository: PreferencesRepository,
    private val tagRepository: TagRepository,
    private val eventRepository: EventRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(OnboardingUiState())
    val uiState: StateFlow<OnboardingUiState> = _uiState.asStateFlow()

    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    init {
        loadGenres()
        loadEventImages()
    }

    private fun loadGenres() {
        viewModelScope.launch {
            tagRepository.allTags.collect { tags ->
                _uiState.update { state ->
                    state.copy(availableGenres = tags.map { it.name })
                }
            }
        }
    }

    private fun loadEventImages() {
        viewModelScope.launch {
            eventRepository.allEvents.collect { events ->
                // Get unique image URLs from events with valid images
                val imageUrls = events
                    .filter { it.imageUrl.isNotBlank() }
                    .map { it.imageUrl }
                    .distinct()
                    .take(12) // Max 12 images for mosaic (4 per row x 3 rows)

                _uiState.update { state ->
                    state.copy(eventImageUrls = imageUrls)
                }
            }
        }
    }

    fun nextStep() {
        _uiState.update { state ->
            val nextStep = when (state.currentStep) {
                OnboardingStep.WELCOME -> OnboardingStep.LOCATION
                OnboardingStep.LOCATION -> OnboardingStep.GENRES
                OnboardingStep.GENRES -> OnboardingStep.NOTIFICATIONS
                OnboardingStep.NOTIFICATIONS -> OnboardingStep.COMPLETE
                OnboardingStep.COMPLETE -> OnboardingStep.COMPLETE
            }
            state.copy(currentStep = nextStep)
        }

        // Save preferences when completing
        if (_uiState.value.currentStep == OnboardingStep.COMPLETE) {
            savePreferences()
        }
    }

    fun previousStep() {
        _uiState.update { state ->
            val prevStep = when (state.currentStep) {
                OnboardingStep.WELCOME -> OnboardingStep.WELCOME
                OnboardingStep.LOCATION -> OnboardingStep.WELCOME
                OnboardingStep.GENRES -> OnboardingStep.LOCATION
                OnboardingStep.NOTIFICATIONS -> OnboardingStep.GENRES
                OnboardingStep.COMPLETE -> OnboardingStep.NOTIFICATIONS
            }
            state.copy(currentStep = prevStep)
        }
    }

    fun skipStep() {
        nextStep()
    }

    @SuppressLint("MissingPermission")
    fun detectCurrentLocation() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingLocation = true) }

            try {
                val location = fusedLocationClient.lastLocation.await()
                if (location != null) {
                    val geocoder = Geocoder(context, Locale.getDefault())
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocation(location.latitude, location.longitude, 1)
                    val cityName = addresses?.firstOrNull()?.locality
                        ?: addresses?.firstOrNull()?.subAdminArea
                        ?: addresses?.firstOrNull()?.adminArea
                        ?: "Unknown Location"

                    _uiState.update { state ->
                        state.copy(
                            locationName = cityName.uppercase(),
                            locationLat = location.latitude,
                            locationLon = location.longitude,
                            isLoadingLocation = false
                        )
                    }

                    // Save location
                    preferencesRepository.setLocation(cityName, location.latitude, location.longitude)

                    // Auto-advance after detecting location (like iOS)
                    kotlinx.coroutines.delay(500)
                    nextStep()
                } else {
                    _uiState.update { it.copy(isLoadingLocation = false) }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoadingLocation = false) }
            }
        }
    }

    fun setLocationManually(cityName: String) {
        viewModelScope.launch {
            _uiState.update { state ->
                state.copy(locationName = cityName)
            }
            preferencesRepository.setLocation(cityName, null, null)
        }
    }

    fun toggleGenre(genre: String) {
        _uiState.update { state ->
            val newSelection = if (state.selectedGenres.contains(genre)) {
                state.selectedGenres - genre
            } else {
                state.selectedGenres + genre
            }
            state.copy(selectedGenres = newSelection)
        }
    }

    fun setNotificationsEnabled(enabled: Boolean) {
        _uiState.update { it.copy(notificationsEnabled = enabled) }
    }

    private fun savePreferences() {
        viewModelScope.launch {
            val state = _uiState.value

            preferencesRepository.setSelectedGenres(state.selectedGenres.toList())
            preferencesRepository.setNotificationsEnabled(state.notificationsEnabled)
            preferencesRepository.setOnboardingCompleted(true)
        }
    }
}
