package com.burner.app.ui.screens.auth

import android.util.Patterns
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.services.AuthResult
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PasswordlessAuthUiState(
    val email: String = "",
    val isLoading: Boolean = false,
    val emailSent: Boolean = false,
    val error: String? = null,
    val canResend: Boolean = false,
    val resendCountdown: Int = 60,
    val isAuthenticated: Boolean = false
)

@HiltViewModel
class PasswordlessAuthViewModel @Inject constructor(
    private val authService: AuthService
) : ViewModel() {

    private val _uiState = MutableStateFlow(PasswordlessAuthUiState())
    val uiState: StateFlow<PasswordlessAuthUiState> = _uiState.asStateFlow()

    private var countdownJob: Job? = null

    fun updateEmail(email: String) {
        _uiState.update { it.copy(email = email) }
    }

    fun isButtonEnabled(): Boolean {
        return isValidEmail(_uiState.value.email)
    }

    suspend fun sendMagicLink() {
        val email = _uiState.value.email
        if (!isValidEmail(email)) {
            showError("Please enter a valid email address")
            return
        }

        _uiState.update { it.copy(isLoading = true, error = null) }

        when (val result = authService.sendMagicLink(email)) {
            is AuthResult.Success -> {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        emailSent = true
                    )
                }
                startCountdown()
            }
            is AuthResult.Error -> {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "Failed to send link: ${result.message}"
                    )
                }
            }
        }
    }

    fun resetEmailSent() {
        stopCountdown()
        _uiState.update {
            it.copy(
                emailSent = false,
                canResend = false,
                resendCountdown = 60
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    private fun startCountdown() {
        countdownJob?.cancel()
        _uiState.update {
            it.copy(
                canResend = false,
                resendCountdown = 60
            )
        }

        countdownJob = viewModelScope.launch {
            while (_uiState.value.resendCountdown > 0) {
                delay(1000)
                _uiState.update {
                    it.copy(resendCountdown = it.resendCountdown - 1)
                }
            }
            _uiState.update { it.copy(canResend = true) }
        }
    }

    private fun stopCountdown() {
        countdownJob?.cancel()
        countdownJob = null
    }

    private fun isValidEmail(email: String): Boolean {
        return email.isNotBlank() && Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }

    private fun showError(message: String) {
        _uiState.update {
            it.copy(
                isLoading = false,
                error = message
            )
        }
    }

    override fun onCleared() {
        super.onCleared()
        stopCountdown()
    }
}
