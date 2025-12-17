package com.burner.app.ui.screens.tickets

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.burner.app.ui.components.LoadingView
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerTypography
import com.stripe.android.paymentsheet.PaymentSheet
import com.stripe.android.paymentsheet.rememberPaymentSheet

@Composable
fun TicketPurchaseScreen(
    eventId: String,
    onDismiss: () -> Unit,
    onPurchaseComplete: () -> Unit,
    viewModel: TicketPurchaseViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Initialize the Stripe Payment Sheet
    val paymentSheet = rememberPaymentSheet(paymentResultCallback = viewModel::onPaymentSheetResult)

    LaunchedEffect(eventId) {
        viewModel.loadEvent(eventId)
    }

    LaunchedEffect(uiState.purchaseSuccess) {
        if (uiState.purchaseSuccess) {
            onPurchaseComplete()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onDismiss) {
                Icon(
                    imageVector = Icons.Filled.ChevronLeft,
                    contentDescription = "Back",
                    tint = BurnerColors.White
                )
            }
            Text(
                text = "Purchase Ticket",
                style = BurnerTypography.body,
                color = BurnerColors.White,
                modifier = Modifier.padding(start = 16.dp)
            )
        }

        if (uiState.isLoading) {
            LoadingView()
        } else if (uiState.event == null) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Event not found", color = BurnerColors.White)
            }
        } else {
            val event = uiState.event!!

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(bottom = 20.dp)
            ) {
                // Event Header
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    AsyncImage(
                        model = event.imageUrl,
                        contentDescription = null,
                        modifier = Modifier
                            .size(60.dp)
                            .clip(RoundedCornerShape(8.dp)),
                        contentScale = ContentScale.Crop
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(event.name, style = BurnerTypography.body, color = BurnerColors.White)
                        Text(event.venue, style = BurnerTypography.caption, color = BurnerColors.TextSecondary)
                    }
                }


                // Price Summary
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp)
                        .background(BurnerColors.White.copy(alpha = 0.05f), RoundedCornerShape(12.dp))
                        .padding(20.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Total", style = BurnerTypography.card, color = BurnerColors.White)
                    Text("£${String.format("%.2f", uiState.totalPrice)}", style = BurnerTypography.card, color = BurnerColors.White)
                }

                Spacer(modifier = Modifier.weight(1f))

                // Error Message
                if (uiState.errorMessage != null) {
                    Text(
                        text = uiState.errorMessage!!,
                        color = BurnerColors.Error,
                        style = BurnerTypography.caption,
                        modifier = Modifier.padding(16.dp).fillMaxWidth(),
                        textAlign = TextAlign.Center
                    )
                }

                // Terms
                Text(
                    text = "By continuing, you agree to our Terms & Privacy Policy",
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextSecondary,
                    modifier = Modifier.padding(20.dp).align(Alignment.CenterHorizontally),
                    textAlign = TextAlign.Center
                )

                // Buy Button
                Button(
                    onClick = {
                        // 1. Trigger checkout in VM
                        viewModel.checkout {
                            // 2. On success, this callback launches the sheet
                            val secret = viewModel.uiState.value.clientSecret
                            if (secret != null) {
                                paymentSheet.presentWithPaymentIntent(
                                    paymentIntentClientSecret = secret,
                                    configuration = PaymentSheet.Configuration(
                                        merchantDisplayName = "BURNER",
                                        // Note: Your backend createPaymentIntent does not return
                                        // ephemeralKey/customerId yet, so we cannot enable
                                        // the 'Saved Cards' checkbox here.
                                        // This matches your provided iOS PaymentSheet config.
                                        allowsDelayedPaymentMethods = false
                                    )
                                )
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                        .height(50.dp),
                    enabled = !uiState.isProcessing && !uiState.purchaseSuccess,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = BurnerColors.White,
                        contentColor = BurnerColors.Black
                    ),
                    shape = CircleShape
                ) {
                    if (uiState.isProcessing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = BurnerColors.Black,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(Icons.Filled.CreditCard, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text("CHECKOUT £${String.format("%.2f", uiState.totalPrice)}")
                    }
                }
            }
        }
    }
}