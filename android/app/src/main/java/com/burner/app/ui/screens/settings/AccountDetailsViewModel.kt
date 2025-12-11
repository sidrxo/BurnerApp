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

data class AccountDetailsUiState(
    val email: String? = null,
    val displayName: String? = null,
    val provider: String? = null,
    val userRole: String? = null
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
    }

    private fun loadUserData() {
        viewModelScope.launch {
            authService.authStateFlow.collect { user ->
                if (user != null) {
                    val profile = authService.getUserProfile(user.uid)
                    // Fetch role from custom claims (authoritative source)
                    val role = authService.getUserRole() ?: UserRole.USER

                    _uiState.update {
                        it.copy(
                            email = user.email,
                            displayName = user.displayName ?: profile?.displayName,
                            provider = profile?.provider,
                            userRole = role
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
