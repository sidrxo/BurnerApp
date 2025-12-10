package com.burner.app.ui.screens.tickets

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ConfirmationNumber
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.burner.app.data.models.Ticket
import com.burner.app.data.models.TicketStatus
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

enum class TicketFilter { UPCOMING, PAST }

@Composable
fun TicketsScreen(
    onTicketClick: (String) -> Unit,
    onSignInClick: () -> Unit,
    viewModel: TicketsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedFilter by remember { mutableStateOf(TicketFilter.UPCOMING) }

    val filteredTickets = when (selectedFilter) {
        TicketFilter.UPCOMING -> uiState.tickets.filter { it.isUpcoming }
        TicketFilter.PAST -> uiState.tickets.filter { it.isPast }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Header
        BurnerTopBar(title = "TICKETS")

        if (!uiState.isAuthenticated) {
            // Not signed in
            EmptyStateView(
                title = "SIGN IN",
                subtitle = "Sign in to view your tickets",
                icon = Icons.Outlined.ConfirmationNumber,
                action = {
                    PrimaryButton(
                        text = "SIGN IN",
                        onClick = onSignInClick,
                        modifier = Modifier.width(200.dp)
                    )
                }
            )
        } else if (uiState.isLoading) {
            LoadingView()
        } else {
            // Filter tabs
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = BurnerDimensions.paddingScreen),
                horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm)
            ) {
                ChipButton(
                    text = "UPCOMING",
                    selected = selectedFilter == TicketFilter.UPCOMING,
                    onClick = { selectedFilter = TicketFilter.UPCOMING }
                )
                ChipButton(
                    text = "PAST",
                    selected = selectedFilter == TicketFilter.PAST,
                    onClick = { selectedFilter = TicketFilter.PAST }
                )
            }

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            if (filteredTickets.isEmpty()) {
                EmptyStateView(
                    title = if (selectedFilter == TicketFilter.UPCOMING) "NO UPCOMING TICKETS" else "NO PAST TICKETS",
                    subtitle = if (selectedFilter == TicketFilter.UPCOMING) "Your upcoming event tickets will appear here" else "Your past event tickets will appear here",
                    icon = Icons.Outlined.ConfirmationNumber
                )
            } else {
                // Tickets grid
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(BurnerDimensions.paddingScreen),
                    horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm),
                    verticalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm)
                ) {
                    items(filteredTickets, key = { it.id ?: "" }) { ticket ->
                        TicketCard(
                            ticket = ticket,
                            onClick = { ticket.id?.let { onTicketClick(it) } }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun TicketCard(
    ticket: Ticket,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .aspectRatio(0.7f)
            .clip(RoundedCornerShape(BurnerDimensions.radiusMd))
            .background(BurnerColors.CardBackground)
            .clickable(onClick = onClick)
    ) {
        // Gradient background placeholder
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            BurnerColors.SurfaceVariant,
                            BurnerColors.Background
                        )
                    )
                )
        )

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(BurnerDimensions.spacingSm),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Status badge
            StatusBadge(status = ticket.status)

            Column {
                // Event name
                Text(
                    text = ticket.eventName,
                    style = BurnerTypography.secondary,
                    color = BurnerColors.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXs))

                // Date
                ticket.startDate?.let { date ->
                    Text(
                        text = formatShortDate(date),
                        style = BurnerTypography.caption,
                        color = BurnerColors.TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXs))

                // Venue
                Text(
                    text = ticket.venue,
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextDimmed,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun StatusBadge(status: String) {
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
        style = BurnerTypography.caption,
        color = textColor,
        modifier = Modifier
            .background(backgroundColor, RoundedCornerShape(BurnerDimensions.radiusXs))
            .padding(horizontal = BurnerDimensions.spacingSm, vertical = BurnerDimensions.spacingXs)
    )
}

private fun formatShortDate(date: Date): String {
    val format = SimpleDateFormat("d MMM", Locale.getDefault())
    return format.format(date)
}
