package com.burner.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AccountDetailsUiState(
    val email: String? = null,
    val displayName: String? = null,
    val provider: String? = null,
    val locationName: String? = null,
    val selectedGenres: List<String> = emptyList()
)

@HiltViewModel
class AccountDetailsViewModel @Inject constructor(
    private val authService: AuthService,
    private val preferencesRepository: PreferencesRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AccountDetailsUiState())
    val uiState: StateFlow<AccountDetailsUiState> = _uiState.asStateFlow()

    init {
        loadUserData()
        loadPreferences()
    }

    private fun loadUserData() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                if (user != null) {
                    val profile = authService.getUserProfile(user.uid)
                    _uiState.update {
                        it.copy(
                            email = user.email,
                            displayName = user.displayName ?: profile?.displayName,
                            provider = profile?.provider
                        )
                    }
                }
            }
        }
    }

    private fun loadPreferences() {
        viewModelScope.launch {
            preferencesRepository.localPreferences.collect { prefs ->
                _uiState.update {
                    it.copy(
                        locationName = prefs.locationName,
                        selectedGenres = prefs.selectedGenres
                    )
                }
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            authService.signOut()
            preferencesRepository.clearAll()
        }
    }
}
