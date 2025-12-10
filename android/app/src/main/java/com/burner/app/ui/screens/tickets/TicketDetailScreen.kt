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

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background),
        contentAlignment = Alignment.Center
    ) {
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

            // White card in center (matching iOS)
            Box(
                modifier = Modifier
                    .padding(horizontal = 20.dp, vertical = 32.dp)
                    .fillMaxWidth()
                    .wrapContentHeight()
                    .clip(RoundedCornerShape(0.dp)) // iOS has no rounded corners
                    .background(androidx.compose.ui.graphics.Color.White)
                    .padding(vertical = 24.dp)
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Close button at top right (matching iOS)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(end = 22.dp, top = 8.dp),
                        horizontalArrangement = Arrangement.End
                    ) {
                        IconButton(
                            onClick = onBackClick,
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Close,
                                contentDescription = "Close",
                                tint = androidx.compose.ui.graphics.Color.Black
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Info section - left aligned at top (matching iOS)
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 30.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = ticket.eventName.uppercase(),
                            style = BurnerTypography.sectionHeader.copy(
                                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                                letterSpacing = (-1.5).sp
                            ),
                            color = androidx.compose.ui.graphics.Color.Black
                        )

                        Text(
                            text = ticket.venue.uppercase(),
                            style = BurnerTypography.card,
                            color = androidx.compose.ui.graphics.Color.Black
                        )

                        ticket.startDate?.let { date ->
                            Text(
                                text = formatDateDetailed(date),
                                style = BurnerTypography.card,
                                color = androidx.compose.ui.graphics.Color.Black
                            )

                            Text(
                                text = formatTime(date),
                                style = BurnerTypography.card,
                                color = androidx.compose.ui.graphics.Color.Black
                            )
                        }

                        Text(
                            text = ticket.status.uppercase(),
                            style = BurnerTypography.card,
                            color = androidx.compose.ui.graphics.Color.Black
                        )

                        Text(
                            text = ticket.ticketNumber ?: "N/A",
                            style = BurnerTypography.card,
                            color = androidx.compose.ui.graphics.Color.Black
                        )
                    }

                    Spacer(modifier = Modifier.height(30.dp))

                    // QR Code centered (matching iOS)
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        ticket.qrCode?.let { qrData ->
                            QRCodeImage(
                                data = qrData,
                                size = 320.dp
                            )
                        }

                        // Transfer button (matching iOS, if status is confirmed)
                        if (ticket.status == TicketStatus.CONFIRMED) {
                            Spacer(modifier = Modifier.height(10.dp))

                            androidx.compose.material3.TextButton(
                                onClick = { /* TODO: Implement transfer */ }
                            ) {
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "TRANSFER TICKET",
                                        style = BurnerTypography.secondary.copy(
                                            fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                                        ),
                                        color = androidx.compose.ui.graphics.Color.Black
                                    )
                                    Icon(
                                        imageVector = Icons.Filled.ArrowUpward,
                                        contentDescription = "Transfer",
                                        tint = androidx.compose.ui.graphics.Color.Black,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        }
                    }
                }
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

// Date formatting matching iOS
private fun formatDateDetailed(date: Date): String {
    val day = SimpleDateFormat("d", Locale.getDefault()).format(date)
    val month = SimpleDateFormat("MMM", Locale.getDefault()).format(date)
    val year = SimpleDateFormat("yyyy", Locale.getDefault()).format(date)
    return "$day $month $year"
}

private fun formatTime(date: Date): String {
    val format = SimpleDateFormat("HH:mm", Locale.getDefault())
    return format.format(date)
}
