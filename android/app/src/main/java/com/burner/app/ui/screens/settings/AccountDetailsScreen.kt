package com.burner.app.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun AccountDetailsScreen(
    onBackClick: () -> Unit,
    onSignOut: () -> Unit,
    viewModel: AccountDetailsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "ACCOUNT",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(BurnerDimensions.paddingScreen)
        ) {
            // Profile icon
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(BurnerColors.CardBackground, shape = androidx.compose.foundation.shape.CircleShape)
                    .align(Alignment.CenterHorizontally),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Filled.Person,
                    contentDescription = null,
                    tint = BurnerColors.White,
                    modifier = Modifier.size(40.dp)
                )
            }

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

            // User info
            SectionHeader(title = "PROFILE")

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            // Display name
            AccountInfoRow(
                label = "Name",
                value = uiState.displayName ?: "Not set"
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            // Email
            AccountInfoRow(
                label = "Email",
                value = uiState.email ?: "Not set"
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            // Provider
            AccountInfoRow(
                label = "Sign-in method",
                value = uiState.provider?.replaceFirstChar { it.uppercase() } ?: "Email"
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

            // Preferences
            SectionHeader(title = "PREFERENCES")

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            AccountInfoRow(
                label = "Location",
                value = uiState.locationName ?: "Not set"
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            AccountInfoRow(
                label = "Favourite genres",
                value = if (uiState.selectedGenres.isNotEmpty()) {
                    uiState.selectedGenres.joinToString(", ")
                } else {
                    "None selected"
                }
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

            // Account Actions section (matching iOS)
            SectionHeader(title = "ACCOUNT ACTIONS")

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            // Sign Out button
            TextButton(
                text = "Sign Out",
                onClick = {
                    viewModel.signOut()
                    onSignOut()
                },
                color = BurnerColors.Error
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            // Delete Account button
            TextButton(
                text = "Delete Account",
                onClick = { /* TODO */ },
                color = BurnerColors.Error
            )
        }
    }
}

@Composable
private fun AccountInfoRow(
    label: String,
    value: String
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(BurnerColors.CardBackground, shape = androidx.compose.foundation.shape.RoundedCornerShape(BurnerDimensions.radiusMd))
            .padding(BurnerDimensions.spacingLg)
    ) {
        Text(
            text = label.uppercase(),
            style = BurnerTypography.caption,
            color = BurnerColors.TextSecondary
        )
        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXs))
        Text(
            text = value,
            style = BurnerTypography.body,
            color = BurnerColors.White
        )
    }
}
