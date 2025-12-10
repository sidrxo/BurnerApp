package com.burner.app.ui.screens.auth

import android.content.Intent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.burner.app.services.AuthResult
import com.burner.app.services.AuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AuthUiState(
    val email: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val isSignUp: Boolean = false,
    val isLoading: Boolean = false,
    val isSignedIn: Boolean = false,
    val error: String? = null,
    val emailError: String? = null,
    val passwordError: String? = null,
    val confirmPasswordError: String? = null,
    val passwordResetSent: Boolean = false
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authService: AuthService
) : ViewModel() {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    fun updateEmail(email: String) {
        _uiState.update { it.copy(email = email, emailError = null, error = null) }
    }

    fun updatePassword(password: String) {
        _uiState.update { it.copy(password = password, passwordError = null, error = null) }
    }

    fun updateConfirmPassword(password: String) {
        _uiState.update { it.copy(confirmPassword = password, confirmPasswordError = null, error = null) }
    }

    fun toggleSignUpMode() {
        _uiState.update {
            it.copy(
                isSignUp = !it.isSignUp,
                error = null,
                emailError = null,
                passwordError = null,
                confirmPasswordError = null
            )
        }
    }

    fun signIn() {
        val state = _uiState.value

        // Validate
        if (!validateEmail(state.email)) return
        if (!validatePassword(state.password)) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            when (val result = authService.signInWithEmail(state.email, state.password)) {
                is AuthResult.Success -> {
                    _uiState.update { it.copy(isLoading = false, isSignedIn = true) }
                }
                is AuthResult.Error -> {
                    _uiState.update { it.copy(isLoading = false, error = result.message) }
                }
            }
        }
    }

    fun signUp() {
        val state = _uiState.value

        // Validate
        if (!validateEmail(state.email)) return
        if (!validatePassword(state.password)) return
        if (!validateConfirmPassword(state.password, state.confirmPassword)) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            when (val result = authService.signUpWithEmail(state.email, state.password)) {
                is AuthResult.Success -> {
                    _uiState.update { it.copy(isLoading = false, isSignedIn = true) }
                }
                is AuthResult.Error -> {
                    _uiState.update { it.copy(isLoading = false, error = result.message) }
                }
            }
        }
    }

    fun getGoogleSignInIntent(): Intent {
        return authService.getGoogleSignInIntent()
    }

    fun signInWithGoogle(idToken: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            when (val result = authService.handleGoogleSignInResult(idToken)) {
                is AuthResult.Success -> {
                    _uiState.update { it.copy(isLoading = false, isSignedIn = true) }
                }
                is AuthResult.Error -> {
                    _uiState.update { it.copy(isLoading = false, error = result.message) }
                }
            }
        }
    }

    fun sendPasswordReset() {
        val email = _uiState.value.email

        if (!validateEmail(email)) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            authService.sendPasswordReset(email)
                .onSuccess {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            passwordResetSent = true,
                            error = "Password reset email sent"
                        )
                    }
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isLoading = false, error = e.message) }
                }
        }
    }

    fun setError(message: String) {
        _uiState.update { it.copy(error = message) }
    }

    private fun validateEmail(email: String): Boolean {
        return if (email.isBlank()) {
            _uiState.update { it.copy(emailError = "Email is required") }
            false
        } else if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            _uiState.update { it.copy(emailError = "Invalid email format") }
            false
        } else {
            true
        }
    }

    private fun validatePassword(password: String): Boolean {
        return if (password.isBlank()) {
            _uiState.update { it.copy(passwordError = "Password is required") }
            false
        } else if (password.length < 6) {
            _uiState.update { it.copy(passwordError = "Password must be at least 6 characters") }
            false
        } else {
            true
        }
    }

    private fun validateConfirmPassword(password: String, confirmPassword: String): Boolean {
        return if (confirmPassword != password) {
            _uiState.update { it.copy(confirmPasswordError = "Passwords do not match") }
            false
        } else {
            true
        }
    }
}
