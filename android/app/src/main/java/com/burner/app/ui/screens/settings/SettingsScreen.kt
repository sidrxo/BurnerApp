package com.burner.app.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
                    onClick = onAccountClick
                )

                SettingsRow(
                    title = "Payment Methods",
                    onClick = onPaymentClick
                )

                SettingsRow(
                    title = "Notifications",
                    onClick = onNotificationsClick
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
                onClick = { /* Placeholder */ }
            )

            // Support section
            SectionHeader(
                title = "SUPPORT",
                modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
            )

            SettingsRow(
                title = "Help & Support",
                onClick = onSupportClick
            )

            SettingsRow(
                title = "FAQ",
                onClick = onFAQClick
            )

            // Legal section
            SectionHeader(
                title = "LEGAL",
                modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
            )

            SettingsRow(
                title = "Terms of Service",
                onClick = onTermsClick
            )

            SettingsRow(
                title = "Privacy Policy",
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
