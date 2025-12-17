package com.burner.app.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.outlined.CreditCard
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
fun PaymentSettingsScreen(
    onBackClick: () -> Unit,
    viewModel: PaymentSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "PAYMENT",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(BurnerDimensions.paddingScreen)
        ) {
            SectionHeader(title = "PAYMENT METHODS")

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            if (uiState.savedCards.isEmpty()) {
                // Empty state
                EmptyStateView(
                    title = "NO PAYMENT METHODS",
                    subtitle = "Add a card to make purchases faster",
                    icon = Icons.Outlined.CreditCard,
                    modifier = Modifier.height(200.dp)
                )
            } else {
                // Saved cards
                uiState.savedCards.forEach { card ->
                    SavedCardRow(
                        brand = card.brand,
                        last4 = card.last4,
                        expiry = card.expiryDisplay,
                        isDefault = card.isDefault,
                        onRemove = { viewModel.removeCard(card.id) }
                    )
                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))
                }
            }

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

            // Add card button
            SecondaryButton(
                text = "ADD PAYMENT METHOD",
                onClick = { /* TODO: Open Stripe payment sheet */ },
                icon = Icons.Filled.Add
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

            // Info
            Text(
                text = "Your payment information is securely stored by Stripe. We never store your full card details.",
                style = BurnerTypography.caption,
                color = BurnerColors.TextDimmed
            )
        }
    }
}

@Composable
private fun SavedCardRow(
    brand: String,
    last4: String,
    expiry: String,
    isDefault: Boolean,
    onRemove: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(BurnerColors.CardBackground, shape = androidx.compose.foundation.shape.RoundedCornerShape(BurnerDimensions.radiusMd))
            .padding(BurnerDimensions.spacingLg),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Filled.CreditCard,
            contentDescription = null,
            tint = BurnerColors.White,
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(BurnerDimensions.spacingMd))

        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "$brand •••• $last4",
                    style = BurnerTypography.body,
                    color = BurnerColors.White
                )
                if (isDefault) {
                    Spacer(modifier = Modifier.width(BurnerDimensions.spacingSm))
                    Text(
                        text = "DEFAULT",
                        style = BurnerTypography.caption,
                        color = BurnerColors.Success,
                        modifier = Modifier
                            .background(
                                BurnerColors.Success.copy(alpha = 0.2f),
                                shape = androidx.compose.foundation.shape.RoundedCornerShape(BurnerDimensions.radiusXs)
                            )
                            .padding(horizontal = BurnerDimensions.spacingSm, vertical = BurnerDimensions.spacingXxs)
                    )
                }
            }
            Text(
                text = "Expires $expiry",
                style = BurnerTypography.caption,
                color = BurnerColors.TextSecondary
            )
        }

        TextButton(
            text = "Remove",
            onClick = onRemove,
            color = BurnerColors.Error
        )
    }
}
