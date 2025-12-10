package com.burner.app.ui.screens.tickets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.burner.app.data.models.PaymentState
import com.burner.app.data.models.SavedCard
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

/**
 * Ticket Purchase Screen matching iOS TicketPurchaseView
 */
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
        // Header with back/close button (like iOS toolbar)
        PurchaseTopBar(
            title = "Purchase Ticket",
            showBackButton = uiState.currentStep != PurchaseStep.PAYMENT_METHOD,
            onBackClick = { viewModel.goBack() },
            onDismiss = onDismiss
        )

        if (uiState.isLoading) {
            LoadingView()
        } else if (uiState.event == null) {
            EmptyStateView(
                title = "Event Not Found",
                subtitle = "Unable to load event details"
            )
        } else {
            val event = uiState.event!!

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // Event header (like iOS eventHeader)
                EventHeader(
                    imageUrl = event.imageUrl,
                    name = event.name,
                    venue = event.venue
                )

                HorizontalDivider(
                    color = BurnerColors.White.copy(alpha = 0.05f)
                )

                when (uiState.currentStep) {
                    PurchaseStep.PAYMENT_METHOD -> {
                        PaymentMethodStep(
                            totalPrice = uiState.totalPrice,
                            hasSavedCards = uiState.savedCards.isNotEmpty(),
                            onCardClick = { viewModel.goToSavedCards() },
                            isProcessing = uiState.paymentState is PaymentState.Processing
                        )
                    }

                    PurchaseStep.CARD_INPUT -> {
                        CardInputStep(
                            totalPrice = uiState.totalPrice,
                            cardNumber = uiState.cardNumber,
                            expiryDate = uiState.expiryDate,
                            cvv = uiState.cvv,
                            isCardValid = uiState.isCardValid,
                            isProcessing = uiState.paymentState is PaymentState.Processing,
                            errorMessage = uiState.errorMessage,
                            onCardNumberChange = viewModel::updateCardNumber,
                            onExpiryDateChange = viewModel::updateExpiryDate,
                            onCvvChange = viewModel::updateCvv,
                            onPayClick = viewModel::processCardPayment
                        )
                    }

                    PurchaseStep.SAVED_CARDS -> {
                        SavedCardsStep(
                            totalPrice = uiState.totalPrice,
                            savedCards = uiState.savedCards,
                            selectedCard = uiState.selectedSavedCard,
                            isProcessing = uiState.paymentState is PaymentState.Processing,
                            errorMessage = uiState.errorMessage,
                            onCardSelect = viewModel::selectSavedCard,
                            onAddNewClick = viewModel::goToCardInput,
                            onPayClick = viewModel::processSavedCardPayment
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PurchaseTopBar(
    title: String,
    showBackButton: Boolean,
    onBackClick: () -> Unit,
    onDismiss: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(
            onClick = if (showBackButton) onBackClick else onDismiss,
            modifier = Modifier.size(40.dp)
        ) {
            Icon(
                imageVector = if (showBackButton) Icons.Filled.ChevronLeft else Icons.Filled.Close,
                contentDescription = if (showBackButton) "Back" else "Close",
                tint = BurnerColors.White
            )
        }

        Text(
            text = title,
            style = BurnerTypography.body,
            color = BurnerColors.White
        )

        // Spacer for symmetry
        Spacer(modifier = Modifier.size(40.dp))
    }
}

@Composable
private fun EventHeader(
    imageUrl: String,
    name: String,
    venue: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AsyncImage(
            model = imageUrl,
            contentDescription = name,
            modifier = Modifier
                .size(60.dp)
                .clip(RoundedCornerShape(8.dp)),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = name,
                style = BurnerTypography.body,
                color = BurnerColors.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = venue,
                style = BurnerTypography.body,
                color = BurnerColors.TextSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun PriceSummary(totalPrice: Double) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp)
            .background(
                color = BurnerColors.White.copy(alpha = 0.05f),
                shape = RoundedCornerShape(12.dp)
            )
            .padding(20.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Total",
            style = BurnerTypography.card,
            color = BurnerColors.White
        )
        Text(
            text = "£${String.format("%.2f", totalPrice)}",
            style = BurnerTypography.card,
            color = BurnerColors.White
        )
    }
}

@Composable
private fun PaymentMethodStep(
    totalPrice: Double,
    hasSavedCards: Boolean,
    onCardClick: () -> Unit,
    isProcessing: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(vertical = 20.dp)
    ) {
        PriceSummary(totalPrice)

        HorizontalDivider(
            modifier = Modifier.padding(horizontal = 20.dp),
            color = BurnerColors.White.copy(alpha = 0.05f)
        )

        Spacer(modifier = Modifier.weight(1f))

        // Terms and conditions
        Row(
            modifier = Modifier
                .padding(horizontal = 20.dp)
                .padding(bottom = 16.dp),
            horizontalArrangement = Arrangement.Center
        ) {
            Text(
                text = "By continuing, you agree to our ",
                style = BurnerTypography.caption,
                color = BurnerColors.White.copy(alpha = 0.7f)
            )
            Text(
                text = "Terms",
                style = BurnerTypography.caption,
                color = BurnerColors.White
            )
            Text(
                text = " & ",
                style = BurnerTypography.caption,
                color = BurnerColors.White.copy(alpha = 0.7f)
            )
            Text(
                text = "Privacy Policy",
                style = BurnerTypography.caption,
                color = BurnerColors.White
            )
        }

        // Payment buttons (like iOS)
        Column(
            modifier = Modifier
                .padding(horizontal = 20.dp)
                .padding(bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Buy with Card button (white capsule)
            Button(
                onClick = onCardClick,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                enabled = !isProcessing,
                colors = ButtonDefaults.buttonColors(
                    containerColor = BurnerColors.Black.copy(alpha = 0.8f),
                    contentColor = BurnerColors.White
                ),
                shape = CircleShape,
                border = androidx.compose.foundation.BorderStroke(1.dp, BurnerColors.White.copy(alpha = 0.3f))
            ) {
                Icon(
                    imageVector = Icons.Filled.CreditCard,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "BUY WITH CARD",
                    style = BurnerTypography.button
                )
            }
        }
    }
}

@Composable
private fun CardInputStep(
    totalPrice: Double,
    cardNumber: String,
    expiryDate: String,
    cvv: String,
    isCardValid: Boolean,
    isProcessing: Boolean,
    errorMessage: String?,
    onCardNumberChange: (String) -> Unit,
    onExpiryDateChange: (String) -> Unit,
    onCvvChange: (String) -> Unit,
    onPayClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(vertical = 20.dp)
    ) {
        PriceSummary(totalPrice)

        HorizontalDivider(
            modifier = Modifier.padding(horizontal = 20.dp),
            color = BurnerColors.White.copy(alpha = 0.05f)
        )

        Spacer(modifier = Modifier.weight(1f))

        // Card input fields
        Column(
            modifier = Modifier.padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedTextField(
                value = cardNumber,
                onValueChange = onCardNumberChange,
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
                    cursorColor = BurnerColors.White,
                    focusedLabelColor = BurnerColors.White,
                    unfocusedLabelColor = BurnerColors.TextSecondary
                )
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = expiryDate,
                    onValueChange = onExpiryDateChange,
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
                        cursorColor = BurnerColors.White,
                        focusedLabelColor = BurnerColors.White,
                        unfocusedLabelColor = BurnerColors.TextSecondary
                    )
                )

                OutlinedTextField(
                    value = cvv,
                    onValueChange = onCvvChange,
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
                        cursorColor = BurnerColors.White,
                        focusedLabelColor = BurnerColors.White,
                        unfocusedLabelColor = BurnerColors.TextSecondary
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Error message
        if (errorMessage != null) {
            Text(
                text = errorMessage,
                style = BurnerTypography.secondary,
                color = BurnerColors.Error,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 12.dp)
            )
        }

        // Pay button
        Button(
            onClick = onPayClick,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 20.dp)
                .height(50.dp),
            enabled = isCardValid && !isProcessing,
            colors = ButtonDefaults.buttonColors(
                containerColor = if (isCardValid) BurnerColors.White else BurnerColors.TextSecondary.copy(alpha = 0.5f),
                contentColor = if (isCardValid) BurnerColors.Black else BurnerColors.TextSecondary
            ),
            shape = CircleShape
        ) {
            if (isProcessing) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = BurnerColors.Black,
                    strokeWidth = 2.dp
                )
            } else {
                Icon(
                    imageVector = Icons.Filled.CreditCard,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "PAY £${String.format("%.2f", totalPrice)}",
                    style = BurnerTypography.button
                )
            }
        }
    }
}

@Composable
private fun SavedCardsStep(
    totalPrice: Double,
    savedCards: List<SavedCard>,
    selectedCard: SavedCard?,
    isProcessing: Boolean,
    errorMessage: String?,
    onCardSelect: (SavedCard) -> Unit,
    onAddNewClick: () -> Unit,
    onPayClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(vertical = 20.dp)
    ) {
        PriceSummary(totalPrice)

        HorizontalDivider(
            modifier = Modifier.padding(horizontal = 20.dp),
            color = BurnerColors.White.copy(alpha = 0.05f)
        )

        Spacer(modifier = Modifier.weight(1f))

        // Saved cards section
        Column(modifier = Modifier.padding(horizontal = 20.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Select Payment Method",
                    style = BurnerTypography.card,
                    color = BurnerColors.White
                )
                TextButton(onClick = onAddNewClick) {
                    Text(
                        text = "Add New",
                        style = BurnerTypography.body,
                        color = BurnerColors.White
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Card list
            savedCards.forEach { card ->
                SavedCardItem(
                    card = card,
                    isSelected = selectedCard?.id == card.id,
                    onClick = { onCardSelect(card) }
                )
                Spacer(modifier = Modifier.height(12.dp))
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Error message
        if (errorMessage != null) {
            Text(
                text = errorMessage,
                style = BurnerTypography.secondary,
                color = BurnerColors.Error,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 12.dp)
            )
        }

        // Pay button
        Button(
            onClick = onPayClick,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 20.dp)
                .height(50.dp),
            enabled = selectedCard != null && !isProcessing,
            colors = ButtonDefaults.buttonColors(
                containerColor = if (selectedCard != null) BurnerColors.White else BurnerColors.TextSecondary.copy(alpha = 0.5f),
                contentColor = if (selectedCard != null) BurnerColors.Black else BurnerColors.TextSecondary
            ),
            shape = CircleShape
        ) {
            if (isProcessing) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = BurnerColors.Black,
                    strokeWidth = 2.dp
                )
            } else {
                Icon(
                    imageVector = Icons.Filled.CreditCard,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "PAY £${String.format("%.2f", totalPrice)}",
                    style = BurnerTypography.button
                )
            }
        }
    }
}

@Composable
private fun SavedCardItem(
    card: SavedCard,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(
                if (isSelected) BurnerColors.Success.copy(alpha = 0.1f)
                else BurnerColors.White.copy(alpha = 0.05f)
            )
            .border(
                width = if (isSelected) 2.dp else 0.dp,
                color = if (isSelected) BurnerColors.Success else Color.Transparent,
                shape = RoundedCornerShape(12.dp)
            )
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Card brand icon
        Box(
            modifier = Modifier
                .size(40.dp, 28.dp)
                .background(
                    color = BurnerColors.White.copy(alpha = 0.1f),
                    shape = RoundedCornerShape(6.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = card.brand.uppercase().take(4),
                style = BurnerTypography.caption.copy(fontSize = 8.sp),
                color = BurnerColors.White
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = card.brand.replaceFirstChar { it.uppercase() },
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextSecondary
                )
                if (card.isDefault) {
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "DEFAULT",
                        style = BurnerTypography.caption.copy(fontSize = 8.sp),
                        color = BurnerColors.Success,
                        modifier = Modifier
                            .background(
                                color = BurnerColors.Success.copy(alpha = 0.2f),
                                shape = RoundedCornerShape(3.dp)
                            )
                            .padding(horizontal = 4.dp, vertical = 2.dp)
                    )
                }
            }
            Text(
                text = "•••• ${card.last4}",
                style = BurnerTypography.body,
                color = BurnerColors.White
            )
            Text(
                text = "Expires ${card.expiryMonth}/${card.expiryYear % 100}",
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

private fun formatDate(date: Date): String {
    val format = SimpleDateFormat("EEE, d MMM 'at' HH:mm", Locale.getDefault())
    return format.format(date)
}
