package com.burner.app.ui.screens.auth

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerTypography
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun PasswordlessAuthScreen(
    onDismiss: () -> Unit,
    onSuccess: () -> Unit,
    viewModel: PasswordlessAuthViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val scope = rememberCoroutineScope()

    LaunchedEffect(uiState.isAuthenticated) {
        if (uiState.isAuthenticated) {
            onSuccess()
            onDismiss()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Top bar with close button
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp),
                contentAlignment = Alignment.CenterEnd
            ) {
                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier
                        .size(38.dp)
                        .background(
                            color = BurnerColors.White.copy(alpha = 0.1f),
                            shape = CircleShape
                        )
                ) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = "Close",
                        tint = BurnerColors.White.copy(alpha = 0.7f),
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            // Scrollable content
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(modifier = Modifier.weight(1f))

                // Header section
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(160.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    if (uiState.emailSent) {
                        // "CHECK YOUR EMAIL" header
                        TightHeader(
                            line1 = "CHECK YOUR",
                            line2 = "EMAIL"
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "We sent a sign-in link to ${uiState.email}",
                            style = BurnerTypography.body,
                            color = BurnerColors.White.copy(alpha = 0.7f),
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 24.dp)
                        )
                    } else {
                        // "WHAT'S YOUR EMAIL?" header
                        TightHeader(
                            line1 = "WHAT'S YOUR",
                            line2 = "EMAIL?"
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "We'll send a magic link to sign you in or create an account.",
                            style = BurnerTypography.body,
                            color = BurnerColors.White.copy(alpha = 0.7f),
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 24.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Content area
                if (!uiState.emailSent) {
                    // Email input
                    OutlinedTextField(
                        value = uiState.email,
                        onValueChange = viewModel::updateEmail,
                        placeholder = {
                            Text(
                                "Email Address",
                                style = BurnerTypography.body,
                                color = BurnerColors.TextSecondary
                            )
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = BurnerColors.White.copy(alpha = 0.2f),
                            unfocusedBorderColor = BurnerColors.White.copy(alpha = 0.2f),
                            focusedTextColor = BurnerColors.White,
                            unfocusedTextColor = BurnerColors.White,
                            cursorColor = BurnerColors.White,
                            focusedContainerColor = BurnerColors.White.copy(alpha = 0.1f),
                            unfocusedContainerColor = BurnerColors.White.copy(alpha = 0.1f)
                        ),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                        textStyle = BurnerTypography.body
                    )
                } else {
                    // Email sent confirmation with instructions
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp),
                        verticalArrangement = Arrangement.spacedBy(28.dp)
                    ) {
                        // Instructions box
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(
                                    color = BurnerColors.White.copy(alpha = 0.05f),
                                    shape = RoundedCornerShape(12.dp)
                                )
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(14.dp)
                        ) {
                            InstructionRow(number = "1", text = "Check your email inbox")
                            InstructionRow(number = "2", text = "Click the sign-in link")
                            InstructionRow(number = "3", text = "You'll be signed in automatically")
                        }

                        // Resend section
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Text(
                                text = "Didn't receive the email?",
                                style = BurnerTypography.caption,
                                color = BurnerColors.White.copy(alpha = 0.7f)
                            )

                            if (uiState.canResend) {
                                SecondaryButton(
                                    text = "RESEND LINK",
                                    onClick = {
                                        scope.launch {
                                            viewModel.sendMagicLink()
                                        }
                                    },
                                    maxWidth = 160.dp
                                )
                            } else {
                                Text(
                                    text = "Resend in ${uiState.resendCountdown}s",
                                    style = BurnerTypography.body,
                                    color = BurnerColors.White.copy(alpha = 0.5f)
                                )
                            }
                        }

                        // Change email button
                        TextButton(
                            onClick = viewModel::resetEmailSent,
                            modifier = Modifier.align(Alignment.CenterHorizontally)
                        ) {
                            Text(
                                text = "Use a different email",
                                style = BurnerTypography.caption,
                                color = BurnerColors.White.copy(alpha = 0.5f),
                                textDecoration = androidx.compose.ui.text.style.TextDecoration.Underline
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.weight(1f))
            }

            // Bottom button (only show when email not sent)
            if (!uiState.emailSent) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(BurnerColors.Background)
                        .padding(horizontal = 24.dp, vertical = 16.dp)
                ) {
                    PrimaryButton(
                        text = "SEND LINK",
                        onClick = {
                            scope.launch {
                                viewModel.sendMagicLink()
                            }
                        },
                        enabled = viewModel.isButtonEnabled() && !uiState.isLoading
                    )
                }
            }
        }

        // Loading overlay
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(BurnerColors.Background.copy(alpha = 0.7f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    color = BurnerColors.White,
                    modifier = Modifier.size(48.dp)
                )
            }
        }

        // Error alert
        if (uiState.error != null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center
            ) {
                Surface(
                    modifier = Modifier
                        .padding(40.dp)
                        .fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = Color.White
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Error",
                            style = BurnerTypography.sectionHeader.copy(fontWeight = FontWeight.Bold),
                            color = Color.Black
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = uiState.error ?: "",
                            style = BurnerTypography.body,
                            color = Color.Black.copy(alpha = 0.7f),
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(20.dp))
                        Button(
                            onClick = viewModel::clearError,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color.Black,
                                contentColor = Color.White
                            ),
                            shape = CircleShape,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("OK", style = BurnerTypography.secondary.copy(fontWeight = FontWeight.Bold))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TightHeader(line1: String, line2: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = line1,
            style = BurnerTypography.pageHeader.copy(
                fontSize = 48.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = (-1.5).sp
            ),
            color = BurnerColors.White,
            textAlign = TextAlign.Center
        )
        Text(
            text = line2,
            style = BurnerTypography.pageHeader.copy(
                fontSize = 48.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = (-1.5).sp
            ),
            color = BurnerColors.White,
            textAlign = TextAlign.Center,
            modifier = Modifier.offset(y = (-15).dp)
        )
    }
}

@Composable
private fun InstructionRow(number: String, text: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(28.dp)
                .background(BurnerColors.White, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = number,
                style = BurnerTypography.secondary.copy(fontWeight = FontWeight.Bold),
                color = Color.Black
            )
        }
        Text(
            text = text,
            style = BurnerTypography.body.copy(lineHeight = 24.sp),
            color = BurnerColors.White,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = BurnerColors.White,
            contentColor = Color.Black,
            disabledContainerColor = BurnerColors.White.copy(alpha = 0.6f),
            disabledContentColor = Color.Black.copy(alpha = 0.6f)
        ),
        shape = CircleShape,
        enabled = enabled
    ) {
        Text(
            text = text,
            style = BurnerTypography.secondary.copy(
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        )
    }
}

@Composable
private fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    maxWidth: androidx.compose.ui.unit.Dp
) {
    OutlinedButton(
        onClick = onClick,
        modifier = Modifier
            .width(maxWidth)
            .height(48.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = Color.Transparent,
            contentColor = BurnerColors.White
        ),
        border = androidx.compose.foundation.BorderStroke(1.dp, BurnerColors.White),
        shape = CircleShape
    ) {
        Text(
            text = text,
            style = BurnerTypography.secondary.copy(
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        )
    }
}
