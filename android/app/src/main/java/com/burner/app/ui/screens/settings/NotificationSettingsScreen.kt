package com.burner.app.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun NotificationSettingsScreen(
    onBackClick: () -> Unit,
    viewModel: NotificationSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "NOTIFICATIONS",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(BurnerDimensions.paddingScreen)
        ) {
            SectionHeader(title = "PUSH NOTIFICATIONS")

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            NotificationToggle(
                title = "Event Reminders",
                subtitle = "Get reminded before events you're attending",
                checked = uiState.eventReminders,
                onCheckedChange = { viewModel.setEventReminders(it) }
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

            NotificationToggle(
                title = "New Events",
                subtitle = "Be notified when new events match your interests",
                checked = uiState.newEvents,
                onCheckedChange = { viewModel.setNewEvents(it) }
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

            NotificationToggle(
                title = "Price Drops",
                subtitle = "Get alerts when saved events go on sale",
                checked = uiState.priceDrops,
                onCheckedChange = { viewModel.setPriceDrops(it) }
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

            SectionHeader(title = "EMAIL NOTIFICATIONS")

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            NotificationToggle(
                title = "Marketing Emails",
                subtitle = "Receive promotional content and updates",
                checked = uiState.marketingEmails,
                onCheckedChange = { viewModel.setMarketingEmails(it) }
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

            NotificationToggle(
                title = "Ticket Confirmations",
                subtitle = "Email confirmations for purchases",
                checked = uiState.ticketConfirmations,
                onCheckedChange = { viewModel.setTicketConfirmations(it) }
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

            Text(
                text = "You can also manage notifications in your device settings.",
                style = BurnerTypography.caption,
                color = BurnerColors.TextDimmed
            )
        }
    }
}

@Composable
private fun NotificationToggle(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(BurnerColors.CardBackground, shape = androidx.compose.foundation.shape.RoundedCornerShape(BurnerDimensions.radiusMd))
            .padding(BurnerDimensions.spacingLg),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = BurnerTypography.body,
                color = BurnerColors.White
            )
            Text(
                text = subtitle,
                style = BurnerTypography.caption,
                color = BurnerColors.TextSecondary
            )
        }

        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = BurnerColors.White,
                checkedTrackColor = BurnerColors.Success,
                uncheckedThumbColor = BurnerColors.TextSecondary,
                uncheckedTrackColor = BurnerColors.CardBackground
            )
        )
    }
}
