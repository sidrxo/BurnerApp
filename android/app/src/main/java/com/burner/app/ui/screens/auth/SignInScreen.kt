package com.burner.app.ui.screens.auth

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.common.api.ApiException
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun SignInScreen(
    onDismiss: () -> Unit,
    onSignInSuccess: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
        try {
            val account = task.getResult(ApiException::class.java)
            account.idToken?.let { idToken ->
                viewModel.signInWithGoogle(idToken)
            }
        } catch (e: ApiException) {
            viewModel.setError("Google sign-in failed")
        }
    }

    LaunchedEffect(uiState.isSignedIn) {
        if (uiState.isSignedIn) {
            onSignInSuccess()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
            .verticalScroll(rememberScrollState())
            .padding(BurnerDimensions.paddingScreen)
    ) {
        SheetTopBar(
            title = if (uiState.isSignUp) "SIGN UP" else "SIGN IN",
            onDismiss = onDismiss
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

        // Email field
        BurnerTextField(
            value = uiState.email,
            onValueChange = viewModel::updateEmail,
            label = "Email",
            placeholder = "Enter your email",
            keyboardType = KeyboardType.Email,
            imeAction = ImeAction.Next,
            isError = uiState.emailError != null,
            errorMessage = uiState.emailError
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))

        // Password field
        BurnerTextField(
            value = uiState.password,
            onValueChange = viewModel::updatePassword,
            label = "Password",
            placeholder = "Enter your password",
            isPassword = true,
            imeAction = if (uiState.isSignUp) ImeAction.Next else ImeAction.Done,
            onImeAction = { if (!uiState.isSignUp) viewModel.signIn() },
            isError = uiState.passwordError != null,
            errorMessage = uiState.passwordError
        )

        // Confirm password for sign up
        if (uiState.isSignUp) {
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))

            BurnerTextField(
                value = uiState.confirmPassword,
                onValueChange = viewModel::updateConfirmPassword,
                label = "Confirm Password",
                placeholder = "Confirm your password",
                isPassword = true,
                imeAction = ImeAction.Done,
                onImeAction = { viewModel.signUp() },
                isError = uiState.confirmPasswordError != null,
                errorMessage = uiState.confirmPasswordError
            )
        }

        // Error message
        if (uiState.error != null) {
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))
            Text(
                text = uiState.error!!,
                style = BurnerTypography.secondary,
                color = BurnerColors.Error,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

        // Primary action button
        PrimaryButton(
            text = if (uiState.isSignUp) "CREATE ACCOUNT" else "SIGN IN",
            onClick = { if (uiState.isSignUp) viewModel.signUp() else viewModel.signIn() },
            isLoading = uiState.isLoading,
            icon = Icons.Filled.Email
        )

        // Forgot password (sign in only)
        if (!uiState.isSignUp) {
            TextButton(
                text = "Forgot password?",
                onClick = { viewModel.sendPasswordReset() },
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )
        }

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

        // Divider
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Divider(modifier = Modifier.weight(1f))
            Text(
                text = "  OR  ",
                style = BurnerTypography.secondary,
                color = BurnerColors.TextSecondary
            )
            Divider(modifier = Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

        // Google Sign In
        SecondaryButton(
            text = "CONTINUE WITH GOOGLE",
            onClick = {
                val intent = viewModel.getGoogleSignInIntent()
                googleSignInLauncher.launch(intent)
            }
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

        // Toggle sign up / sign in
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = if (uiState.isSignUp) "Already have an account?" else "Don't have an account?",
                style = BurnerTypography.secondary,
                color = BurnerColors.TextSecondary
            )
            TextButton(
                text = if (uiState.isSignUp) "Sign In" else "Sign Up",
                onClick = { viewModel.toggleSignUpMode() }
            )
        }
    }
}
