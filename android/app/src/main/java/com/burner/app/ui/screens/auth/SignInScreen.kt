package com.burner.app.ui.screens.auth

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Email
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.common.api.ApiException
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
            val errorCode = e.statusCode
            if (errorCode != 12501) { // 12501 is user cancelled
                viewModel.setError("Google sign-in failed")
            }
        }
    }

    LaunchedEffect(uiState.isSignedIn) {
        if (uiState.isSignedIn) {
            onSignInSuccess()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(BurnerDimensions.paddingScreen),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Close button
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.TopEnd
            ) {
                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier
                        .size(32.dp)
                        .background(
                            color = Color.Black.copy(alpha = 0.1f),
                            shape = CircleShape
                        )
                ) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = "Close",
                        tint = Color.Black.copy(alpha = 0.7f),
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Sign-in buttons
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Google Sign In Button
                Button(
                    onClick = {
                        val intent = viewModel.getGoogleSignInIntent()
                        googleSignInLauncher.launch(intent)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color.Black,
                        disabledContainerColor = Color.White.copy(alpha = 0.5f),
                        disabledContentColor = Color.Black.copy(alpha = 0.5f)
                    ),
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(25.dp),
                    border = BorderStroke(1.5.dp, Color.Black),
                    enabled = !uiState.isLoading
                ) {
                    Text(
                        text = "CONTINUE WITH GOOGLE",
                        style = BurnerTypography.body
                    )
                }

                // Email Sign In Button (Passwordless - stub for now)
                Button(
                    onClick = {
                        viewModel.setError("Passwordless email sign-in coming soon!")
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color.Black,
                        disabledContainerColor = Color.White.copy(alpha = 0.5f),
                        disabledContentColor = Color.Black.copy(alpha = 0.5f)
                    ),
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(25.dp),
                    border = BorderStroke(1.5.dp, Color.Black),
                    enabled = !uiState.isLoading
                ) {
                    Text(
                        text = "CONTINUE WITH EMAIL",
                        style = BurnerTypography.body
                    )
                }
            }

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))

            // Terms and Privacy
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = "By continuing, you agree to our",
                    style = BurnerTypography.caption,
                    color = Color.Black.copy(alpha = 0.6f),
                    textAlign = TextAlign.Center
                )
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(onClick = { /* Navigate to Terms */ }) {
                        Text(
                            text = "Terms of Service",
                            style = BurnerTypography.caption,
                            color = Color.Black,
                            textDecoration = TextDecoration.Underline
                        )
                    }
                    Text(
                        text = " & ",
                        style = BurnerTypography.caption,
                        color = Color.Black.copy(alpha = 0.6f)
                    )
                    TextButton(onClick = { /* Navigate to Privacy */ }) {
                        Text(
                            text = "Privacy Policy",
                            style = BurnerTypography.caption,
                            color = Color.Black,
                            textDecoration = TextDecoration.Underline
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))
        }

        // Loading overlay
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.4f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    color = Color.White,
                    modifier = Modifier.size(40.dp)
                )
            }
        }

        // Error snackbar at bottom
        if (uiState.error != null) {
            Snackbar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp),
                containerColor = BurnerColors.Error,
                contentColor = Color.White,
                action = {
                    TextButton(onClick = { viewModel.clearError() }) {
                        Text("Dismiss", color = Color.White)
                    }
                }
            ) {
                Text(uiState.error!!)
            }
        }
    }
}
