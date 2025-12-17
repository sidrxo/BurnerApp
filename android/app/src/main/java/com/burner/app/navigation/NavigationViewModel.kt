package com.burner.app.navigation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NavigationUiState(
    val hasCompletedOnboarding: Boolean = false,
    val isAuthenticated: Boolean = false,
    val isLoading: Boolean = true
)

@HiltViewModel
class NavigationViewModel @Inject constructor(
    private val preferencesRepository: PreferencesRepository,
    private val authService: AuthService
) : ViewModel() {

    private val _uiState = MutableStateFlow(NavigationUiState())
    val uiState: StateFlow<NavigationUiState> = _uiState.asStateFlow()

    init {
        loadInitialState()
    }

    private fun loadInitialState() {
        viewModelScope.launch {
            preferencesRepository.localPreferences.collect { prefs ->
                _uiState.update { state ->
                    state.copy(
                        hasCompletedOnboarding = prefs.hasCompletedOnboarding,
                        isAuthenticated = authService.isAuthenticated(),
                        isLoading = false
                    )
                }
            }
        }
    }

    fun completeOnboarding() {
        viewModelScope.launch {
            preferencesRepository.setOnboardingCompleted(true)
            _uiState.update { it.copy(hasCompletedOnboarding = true) }
        }
    }

    fun resetOnboarding() {
        viewModelScope.launch {
            preferencesRepository.setOnboardingCompleted(false)
            _uiState.update { it.copy(hasCompletedOnboarding = false) }
        }
    }
}
