package com.burner.app.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.BuildConfig
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun SettingsScreen(
    onBackClick: () -> Unit,
    onAccountClick: () -> Unit,
    onPaymentClick: () -> Unit,
    onNotificationsClick: () -> Unit,
    onScannerClick: () -> Unit,
    onSupportClick: () -> Unit,
    onFAQClick: () -> Unit,
    onTermsClick: () -> Unit,
    onPrivacyClick: () -> Unit,
    onSignInClick: () -> Unit = {},
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Header
        BurnerTopBar(
            title = "SETTINGS",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // Account section
            if (uiState.isAuthenticated) {
                SectionHeader(
                    title = "ACCOUNT",
                    modifier = Modifier.padding(top = BurnerDimensions.spacingLg)
                )

                SettingsRow(
                    title = "Account Details",
                    subtitle = uiState.userEmail,
                    icon = Icons.Filled.Person,
                    onClick = onAccountClick
                )

                SettingsRow(
                    title = "Payment Methods",
                    icon = Icons.Filled.CreditCard,
                    onClick = onPaymentClick
                )

                SettingsRow(
                    title = "Notifications",
                    icon = Icons.Filled.Notifications,
                    onClick = onNotificationsClick
                )
            } else {
                // Not authenticated - show sign in option
                SectionHeader(
                    title = "ACCOUNT",
                    modifier = Modifier.padding(top = BurnerDimensions.spacingLg)
                )

                SettingsRow(
                    title = "Sign In",
                    subtitle = "Sign in to access your account",
                    icon = Icons.Filled.Login,
                    onClick = onSignInClick
                )
            }

            // Scanner section (for authorized roles)
            if (uiState.canAccessScanner) {
                SectionHeader(
                    title = "SCANNER",
                    modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
                )

                SettingsRow(
                    title = "Scan Tickets",
                    subtitle = "Scan QR codes on tickets",
                    icon = Icons.Filled.QrCodeScanner,
                    onClick = onScannerClick
                )
            }

            // Burner Mode section (placeholder)
            SectionHeader(
                title = "BURNER MODE",
                modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
            )

            SettingsRow(
                title = "Burner Mode Settings",
                subtitle = "Configure your offline experience",
                icon = Icons.Filled.PhonelinkLock,
                onClick = { /* Placeholder */ }
            )

            // Support section
            SectionHeader(
                title = "SUPPORT",
                modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
            )

            SettingsRow(
                title = "Help & Support",
                icon = Icons.Filled.Help,
                onClick = onSupportClick
            )

            SettingsRow(
                title = "FAQ",
                icon = Icons.Filled.QuestionAnswer,
                onClick = onFAQClick
            )

            // Legal section
            SectionHeader(
                title = "LEGAL",
                modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
            )

            SettingsRow(
                title = "Terms of Service",
                icon = Icons.Filled.Description,
                onClick = onTermsClick
            )

            SettingsRow(
                title = "Privacy Policy",
                icon = Icons.Filled.PrivacyTip,
                onClick = onPrivacyClick
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

            // Version
            Text(
                text = "Version ${BuildConfig.VERSION_NAME}",
                style = BurnerTypography.caption,
                color = BurnerColors.TextDimmed,
                modifier = Modifier.padding(horizontal = BurnerDimensions.paddingScreen)
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))
        }
    }
}
