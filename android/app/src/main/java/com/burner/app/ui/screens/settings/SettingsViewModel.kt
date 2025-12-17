package com.burner.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.models.UserRole
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val isAuthenticated: Boolean = false,
    val userEmail: String? = null,
    val userName: String? = null,
    val userRole: String? = null,
    val canAccessScanner: Boolean = false
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val authService: AuthService,
    private val preferencesRepository: PreferencesRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        observeAuthState()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                if (user != null) {
                    // Fetch role from custom claims (authoritative source)
                    val role = authService.getUserRole() ?: UserRole.USER

                    _uiState.update {
                        it.copy(
                            isAuthenticated = true,
                            userEmail = user.email,
                            userName = user.displayName,
                            userRole = role,
                            canAccessScanner = true  // Allow all users to see scanner
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            isAuthenticated = false,
                            userEmail = null,
                            userName = null,
                            userRole = null,
                            canAccessScanner = false
                        )
                    }
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
