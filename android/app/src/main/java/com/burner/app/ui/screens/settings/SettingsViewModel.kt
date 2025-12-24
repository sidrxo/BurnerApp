package com.burner.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.BurnerSupabaseClient
import com.burner.shared.models.UserRole
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
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
    private val preferencesRepository: PreferencesRepository,
    private val supabase: BurnerSupabaseClient
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        observeAuthState()
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            // authStateFlow emits Boolean (isAuthenticated), NOT the User object
            authService.authStateFlow.collect { isAuthenticated ->
                if (isAuthenticated) {
                    val user = supabase.auth.currentUserOrNull()

                    if (user != null) {
                        // Fetch role
                        val role = authService.getUserRole() ?: UserRole.USER

                        // Extract display name from metadata (Supabase stores it in user_metadata)
                        val metaName = user.userMetadata?.get("full_name")?.jsonPrimitive?.contentOrNull
                            ?: user.userMetadata?.get("name")?.jsonPrimitive?.contentOrNull

                        _uiState.update {
                            it.copy(
                                isAuthenticated = true,
                                userEmail = user.email,
                                userName = metaName,
                                userRole = role,
                                canAccessScanner = true  // Allow all users to see scanner
                            )
                        }
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