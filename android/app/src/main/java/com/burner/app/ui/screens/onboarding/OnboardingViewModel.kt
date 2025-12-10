package com.burner.app.ui.screens.onboarding

import android.annotation.SuppressLint
import android.content.Context
import android.location.Geocoder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.burner.app.data.models.Tag
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
    val notificationsEnabled: Boolean = false
)

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val preferencesRepository: PreferencesRepository,
    private val tagRepository: TagRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(OnboardingUiState())
    val uiState: StateFlow<OnboardingUiState> = _uiState.asStateFlow()

    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    init {
        loadGenres()
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
                            locationName = cityName,
                            locationLat = location.latitude,
                            locationLon = location.longitude,
                            isLoadingLocation = false
                        )
                    }

                    // Save location
                    preferencesRepository.setLocation(cityName, location.latitude, location.longitude)
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
