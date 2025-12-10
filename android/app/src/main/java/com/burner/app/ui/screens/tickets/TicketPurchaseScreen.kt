package com.burner.app.ui.screens.tickets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.burner.app.data.models.PaymentMethod
import com.burner.app.data.models.PaymentState
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun TicketPurchaseScreen(
    eventId: String,
    onDismiss: () -> Unit,
    onPurchaseComplete: () -> Unit,
    viewModel: TicketPurchaseViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(eventId) {
        viewModel.loadEvent(eventId)
    }

    LaunchedEffect(uiState.paymentState) {
        if (uiState.paymentState is PaymentState.Success) {
            onPurchaseComplete()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Header
        SheetTopBar(
            title = "GET TICKETS",
            onDismiss = onDismiss
        )

        if (uiState.isLoading) {
            LoadingView()
        } else if (uiState.event == null) {
            EmptyStateView(
                title = "EVENT NOT FOUND",
                subtitle = "Unable to load event details"
            )
        } else {
            val event = uiState.event!!

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // Event summary
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(BurnerDimensions.paddingScreen),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    AsyncImage(
                        model = event.imageUrl,
                        contentDescription = event.name,
                        modifier = Modifier
                            .size(80.dp)
                            .clip(RoundedCornerShape(BurnerDimensions.radiusSm)),
                        contentScale = ContentScale.Crop
                    )

                    Spacer(modifier = Modifier.width(BurnerDimensions.spacingMd))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = event.name,
                            style = BurnerTypography.card,
                            color = BurnerColors.White
                        )
                        Text(
                            text = event.venue,
                            style = BurnerTypography.secondary,
                            color = BurnerColors.TextSecondary
                        )
                        event.startDate?.let { date ->
                            Text(
                                text = formatDate(date),
                                style = BurnerTypography.caption,
                                color = BurnerColors.TextTertiary
                            )
                        }
                    }
                }

                Divider(modifier = Modifier.padding(horizontal = BurnerDimensions.paddingScreen))

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))

                // Price breakdown
                Column(
                    modifier = Modifier.padding(horizontal = BurnerDimensions.paddingScreen)
                ) {
                    Text(
                        text = "ORDER SUMMARY",
                        style = BurnerTypography.label,
                        color = BurnerColors.TextSecondary
                    )

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Ticket x ${uiState.quantity}",
                            style = BurnerTypography.body,
                            color = BurnerColors.TextTertiary
                        )
                        Text(
                            text = "£${String.format("%.2f", event.price * uiState.quantity)}",
                            style = BurnerTypography.body,
                            color = BurnerColors.White
                        )
                    }

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Service fee",
                            style = BurnerTypography.body,
                            color = BurnerColors.TextTertiary
                        )
                        Text(
                            text = "£0.00",
                            style = BurnerTypography.body,
                            color = BurnerColors.White
                        )
                    }

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                    Divider()

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Total",
                            style = BurnerTypography.card,
                            color = BurnerColors.White
                        )
                        Text(
                            text = "£${String.format("%.2f", uiState.totalPrice)}",
                            style = BurnerTypography.price,
                            color = BurnerColors.White
                        )
                    }
                }

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

                // Payment method selection
                Column(
                    modifier = Modifier.padding(horizontal = BurnerDimensions.paddingScreen)
                ) {
                    Text(
                        text = "PAYMENT METHOD",
                        style = BurnerTypography.label,
                        color = BurnerColors.TextSecondary
                    )

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                    // Google Pay option
                    PaymentMethodOption(
                        icon = Icons.Filled.Payment,
                        title = "Google Pay",
                        subtitle = "Pay securely with Google",
                        isSelected = uiState.selectedPaymentMethod is PaymentMethod.GooglePay,
                        onClick = { viewModel.selectPaymentMethod(PaymentMethod.GooglePay) }
                    )

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

                    // Card option
                    PaymentMethodOption(
                        icon = Icons.Filled.CreditCard,
                        title = "Credit / Debit Card",
                        subtitle = "Visa, Mastercard, Amex",
                        isSelected = uiState.selectedPaymentMethod is PaymentMethod.Card ||
                                uiState.selectedPaymentMethod is PaymentMethod.NewCard,
                        onClick = { viewModel.selectPaymentMethod(PaymentMethod.NewCard) }
                    )

                    // Card input fields (if card selected)
                    if (uiState.selectedPaymentMethod is PaymentMethod.NewCard) {
                        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                        CardInputFields(
                            cardNumber = uiState.cardNumber,
                            expiryDate = uiState.expiryDate,
                            cvv = uiState.cvv,
                            onCardNumberChange = viewModel::updateCardNumber,
                            onExpiryDateChange = viewModel::updateExpiryDate,
                            onCvvChange = viewModel::updateCvv
                        )
                    }
                }

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

                // Terms
                Text(
                    text = "By purchasing, you agree to our Terms of Service and Privacy Policy",
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextDimmed,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = BurnerDimensions.paddingScreen)
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))

                // Error message
                if (uiState.paymentState is PaymentState.Error) {
                    Text(
                        text = (uiState.paymentState as PaymentState.Error).message,
                        style = BurnerTypography.secondary,
                        color = BurnerColors.Error,
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = BurnerDimensions.paddingScreen)
                    )
                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))
                }

                // Pay button
                PrimaryButton(
                    text = "PAY £${String.format("%.2f", uiState.totalPrice)}",
                    onClick = { viewModel.processPayment() },
                    isLoading = uiState.paymentState is PaymentState.Processing,
                    enabled = uiState.isPaymentValid,
                    modifier = Modifier.padding(horizontal = BurnerDimensions.paddingScreen)
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))
            }
        }
    }
}

@Composable
private fun PaymentMethodOption(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(BurnerDimensions.radiusMd))
            .background(if (isSelected) BurnerColors.CardBackground else BurnerColors.Background)
            .border(
                width = BurnerDimensions.borderNormal,
                color = if (isSelected) BurnerColors.White else BurnerColors.Border,
                shape = RoundedCornerShape(BurnerDimensions.radiusMd)
            )
            .clickable(onClick = onClick)
            .padding(BurnerDimensions.spacingLg),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = BurnerColors.White,
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(BurnerDimensions.spacingMd))

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

        if (isSelected) {
            Icon(
                imageVector = Icons.Filled.CheckCircle,
                contentDescription = "Selected",
                tint = BurnerColors.Success,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

@Composable
private fun CardInputFields(
    cardNumber: String,
    expiryDate: String,
    cvv: String,
    onCardNumberChange: (String) -> Unit,
    onExpiryDateChange: (String) -> Unit,
    onCvvChange: (String) -> Unit
) {
    Column {
        OutlinedTextField(
            value = cardNumber,
            onValueChange = { if (it.length <= 19) onCardNumberChange(it) },
            label = { Text("Card Number") },
            placeholder = { Text("1234 5678 9012 3456") },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            singleLine = true,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = BurnerColors.White,
                unfocusedBorderColor = BurnerColors.Border,
                focusedTextColor = BurnerColors.White,
                unfocusedTextColor = BurnerColors.White,
                cursorColor = BurnerColors.White
            )
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingMd)
        ) {
            OutlinedTextField(
                value = expiryDate,
                onValueChange = { if (it.length <= 5) onExpiryDateChange(it) },
                label = { Text("Expiry") },
                placeholder = { Text("MM/YY") },
                modifier = Modifier.weight(1f),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BurnerColors.White,
                    unfocusedBorderColor = BurnerColors.Border,
                    focusedTextColor = BurnerColors.White,
                    unfocusedTextColor = BurnerColors.White,
                    cursorColor = BurnerColors.White
                )
            )

            OutlinedTextField(
                value = cvv,
                onValueChange = { if (it.length <= 4) onCvvChange(it) },
                label = { Text("CVV") },
                placeholder = { Text("123") },
                modifier = Modifier.weight(1f),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BurnerColors.White,
                    unfocusedBorderColor = BurnerColors.Border,
                    focusedTextColor = BurnerColors.White,
                    unfocusedTextColor = BurnerColors.White,
                    cursorColor = BurnerColors.White
                )
            )
        }
    }
}

private fun formatDate(date: Date): String {
    val format = SimpleDateFormat("EEE, d MMM 'at' HH:mm", Locale.getDefault())
    return format.format(date)
}
