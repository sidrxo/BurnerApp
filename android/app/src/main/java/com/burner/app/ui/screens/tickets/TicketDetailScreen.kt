package com.burner.app.ui.screens.tickets

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import com.burner.app.data.models.Ticket
import com.burner.app.data.models.TicketStatus
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun TicketDetailScreen(
    ticketId: String,
    onBackClick: () -> Unit,
    viewModel: TicketDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(ticketId) {
        viewModel.loadTicket(ticketId)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Top bar
        BurnerTopBar(
            title = "TICKET",
            onBackClick = onBackClick
        )

        if (uiState.isLoading) {
            LoadingView()
        } else if (uiState.ticket == null) {
            EmptyStateView(
                title = "TICKET NOT FOUND",
                subtitle = "This ticket may no longer be available",
                action = {
                    SecondaryButton(
                        text = "GO BACK",
                        onClick = onBackClick,
                        modifier = Modifier.width(200.dp)
                    )
                }
            )
        } else {
            val ticket = uiState.ticket!!

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(BurnerDimensions.paddingScreen),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Ticket card
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(BurnerDimensions.radiusLg))
                        .background(BurnerColors.Surface)
                        .padding(BurnerDimensions.spacingXl),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // QR Code
                        ticket.qrCode?.let { qrData ->
                            QRCodeImage(
                                data = qrData,
                                size = BurnerDimensions.qrCodeSize
                            )
                        }

                        Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))

                        // Ticket number
                        Text(
                            text = ticket.ticketNumber ?: "---",
                            style = BurnerTypography.label,
                            color = BurnerColors.TextSecondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

                // Event details
                Text(
                    text = ticket.eventName,
                    style = BurnerTypography.sectionHeader,
                    color = BurnerColors.White,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                // Status
                TicketStatusChip(status = ticket.status)

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

                // Info rows
                ticket.startDate?.let { date ->
                    TicketInfoRow(
                        icon = Icons.Filled.CalendarToday,
                        label = "DATE",
                        value = formatFullDate(date)
                    )
                }

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                TicketInfoRow(
                    icon = Icons.Filled.LocationOn,
                    label = "VENUE",
                    value = ticket.venue
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                TicketInfoRow(
                    icon = Icons.Filled.Payment,
                    label = "PRICE",
                    value = "£${String.format("%.2f", ticket.totalPrice)}"
                )

                ticket.purchaseDateValue?.let { date ->
                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                    TicketInfoRow(
                        icon = Icons.Filled.Receipt,
                        label = "PURCHASED",
                        value = formatFullDate(date)
                    )
                }

                // Burner Mode placeholder
                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            BurnerColors.CardBackground,
                            RoundedCornerShape(BurnerDimensions.radiusMd)
                        )
                        .padding(BurnerDimensions.spacingLg)
                ) {
                    Column {
                        Text(
                            text = "BURNER MODE",
                            style = BurnerTypography.label,
                            color = BurnerColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXs))
                        Text(
                            text = "Go offline during this event to be fully present",
                            style = BurnerTypography.secondary,
                            color = BurnerColors.TextTertiary
                        )
                        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))
                        SecondaryButton(
                            text = "SET UP BURNER MODE",
                            onClick = { /* Placeholder */ }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))
            }
        }
    }
}

@Composable
private fun QRCodeImage(
    data: String,
    size: androidx.compose.ui.unit.Dp
) {
    val bitmap = remember(data) {
        generateQRCode(data, size.value.toInt())
    }

    bitmap?.let {
        Image(
            bitmap = it.asImageBitmap(),
            contentDescription = "QR Code",
            modifier = Modifier.size(size)
        )
    }
}

private fun generateQRCode(content: String, size: Int): Bitmap? {
    return try {
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(content, BarcodeFormat.QR_CODE, size, size)
        val width = bitMatrix.width
        val height = bitMatrix.height
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)

        for (x in 0 until width) {
            for (y in 0 until height) {
                bitmap.setPixel(
                    x, y,
                    if (bitMatrix[x, y]) android.graphics.Color.BLACK
                    else android.graphics.Color.WHITE
                )
            }
        }
        bitmap
    } catch (e: Exception) {
        null
    }
}

@Composable
private fun TicketStatusChip(status: String) {
    val (backgroundColor, textColor, text) = when (status) {
        TicketStatus.CONFIRMED -> Triple(
            BurnerColors.Success.copy(alpha = 0.2f),
            BurnerColors.Success,
            "CONFIRMED"
        )
        TicketStatus.USED -> Triple(
            BurnerColors.TextSecondary.copy(alpha = 0.2f),
            BurnerColors.TextSecondary,
            "USED"
        )
        TicketStatus.CANCELLED -> Triple(
            BurnerColors.Error.copy(alpha = 0.2f),
            BurnerColors.Error,
            "CANCELLED"
        )
        TicketStatus.REFUNDED -> Triple(
            BurnerColors.Warning.copy(alpha = 0.2f),
            BurnerColors.Warning,
            "REFUNDED"
        )
        else -> Triple(
            BurnerColors.TextSecondary.copy(alpha = 0.2f),
            BurnerColors.TextSecondary,
            status.uppercase()
        )
    }

    Text(
        text = text,
        style = BurnerTypography.label,
        color = textColor,
        modifier = Modifier
            .background(backgroundColor, RoundedCornerShape(BurnerDimensions.radiusFull))
            .padding(horizontal = BurnerDimensions.spacingLg, vertical = BurnerDimensions.spacingSm)
    )
}

@Composable
private fun TicketInfoRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = BurnerColors.TextSecondary,
            modifier = Modifier.size(20.dp)
        )

        Spacer(modifier = Modifier.width(BurnerDimensions.spacingMd))

        Column {
            Text(
                text = label,
                style = BurnerTypography.caption,
                color = BurnerColors.TextSecondary
            )
            Text(
                text = value,
                style = BurnerTypography.body,
                color = BurnerColors.White
            )
        }
    }
}

private fun formatFullDate(date: Date): String {
    val format = SimpleDateFormat("EEEE, d MMMM yyyy 'at' HH:mm", Locale.getDefault())
    return format.format(date)
}
