package com.burner.app.ui.screens.auth;

import android.content.Intent;
import androidx.lifecycle.ViewModel;
import com.burner.app.services.AuthResult;
import com.burner.app.services.AuthService;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.StateFlow;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000B\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u000b\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0007\u0018\u00002\u00020\u0001B\u000f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0006\u0010\f\u001a\u00020\rJ\u0006\u0010\u000e\u001a\u00020\u000fJ\u000e\u0010\u0010\u001a\u00020\u000f2\u0006\u0010\u0011\u001a\u00020\u0012J\u0006\u0010\u0013\u001a\u00020\u000fJ\u000e\u0010\u0014\u001a\u00020\u000f2\u0006\u0010\u0015\u001a\u00020\u0012J\u0006\u0010\u0016\u001a\u00020\u000fJ\u0006\u0010\u0017\u001a\u00020\u000fJ\u000e\u0010\u0018\u001a\u00020\u000f2\u0006\u0010\u0019\u001a\u00020\u0012J\u000e\u0010\u001a\u001a\u00020\u000f2\u0006\u0010\u001b\u001a\u00020\u0012J\u000e\u0010\u001c\u001a\u00020\u000f2\u0006\u0010\u0019\u001a\u00020\u0012J\u0018\u0010\u001d\u001a\u00020\u001e2\u0006\u0010\u0019\u001a\u00020\u00122\u0006\u0010\u001f\u001a\u00020\u0012H\u0002J\u0010\u0010 \u001a\u00020\u001e2\u0006\u0010\u001b\u001a\u00020\u0012H\u0002J\u0010\u0010!\u001a\u00020\u001e2\u0006\u0010\u0019\u001a\u00020\u0012H\u0002R\u0014\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00070\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000b\u00a8\u0006\""}, d2 = {"Lcom/burner/app/ui/screens/auth/AuthViewModel;", "Landroidx/lifecycle/ViewModel;", "authService", "Lcom/burner/app/services/AuthService;", "(Lcom/burner/app/services/AuthService;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/auth/AuthUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "getGoogleSignInIntent", "Landroid/content/Intent;", "sendPasswordReset", "", "setError", "message", "", "signIn", "signInWithGoogle", "idToken", "signUp", "toggleSignUpMode", "updateConfirmPassword", "password", "updateEmail", "email", "updatePassword", "validateConfirmPassword", "", "confirmPassword", "validateEmail", "validatePassword", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class AuthViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.auth.AuthUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.auth.AuthUiState> uiState = null;
    
    @javax.inject.Inject()
    public AuthViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.services.AuthService authService) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.auth.AuthUiState> getUiState() {
        return null;
    }
    
    public final void updateEmail(@org.jetbrains.annotations.NotNull()
    java.lang.String email) {
    }
    
    public final void updatePassword(@org.jetbrains.annotations.NotNull()
    java.lang.String password) {
    }
    
    public final void updateConfirmPassword(@org.jetbrains.annotations.NotNull()
    java.lang.String password) {
    }
    
    public final void toggleSignUpMode() {
    }
    
    public final void signIn() {
    }
    
    public final void signUp() {
    }
    
    @org.jetbrains.annotations.NotNull()
    public final android.content.Intent getGoogleSignInIntent() {
        return null;
    }
    
    public final void signInWithGoogle(@org.jetbrains.annotations.NotNull()
    java.lang.String idToken) {
    }
    
    public final void sendPasswordReset() {
    }
    
    public final void setError(@org.jetbrains.annotations.NotNull()
    java.lang.String message) {
    }
    
    private final boolean validateEmail(java.lang.String email) {
        return false;
    }
    
    private final boolean validatePassword(java.lang.String password) {
        return false;
    }
    
    private final boolean validateConfirmPassword(java.lang.String password, java.lang.String confirmPassword) {
        return false;
    }
}