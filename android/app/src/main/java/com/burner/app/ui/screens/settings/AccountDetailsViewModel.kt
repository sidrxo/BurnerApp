package com.burner.app.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.UserRole
import com.burner.app.data.repository.PreferencesRepository
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
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
    private val preferencesRepository: PreferencesRepository,
    private val supabase: BurnerSupabaseClient
) : ViewModel() {

    private val _uiState = MutableStateFlow(AccountDetailsUiState())
    val uiState: StateFlow<AccountDetailsUiState> = _uiState.asStateFlow()

    init {
        loadUserData()
    }

    private fun loadUserData() {
        viewModelScope.launch {
            // authStateFlow emits Boolean (isAuthenticated), not the User object
            authService.authStateFlow.collect { isAuthenticated ->
                if (isAuthenticated) {
                    // Get the actual user object from Supabase
                    val user = supabase.auth.currentUserOrNull()

                    if (user != null) {
                        val profile = authService.getUserProfile(user.id) // Use 'id', not 'uid'
                        val role = authService.getUserRole() ?: UserRole.USER

                        // Extract display name from metadata (Supabase doesn't have a top-level displayName property)
                        val metaName = user.userMetadata?.get("full_name")?.jsonPrimitive?.contentOrNull
                            ?: user.userMetadata?.get("name")?.jsonPrimitive?.contentOrNull

                        _uiState.update {
                            it.copy(
                                email = user.email,
                                displayName = metaName ?: profile?.displayName,
                                provider = profile?.provider ?: user.appMetadata?.get("provider")?.jsonPrimitive?.contentOrNull,
                                userRole = role
                            )
                        }
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