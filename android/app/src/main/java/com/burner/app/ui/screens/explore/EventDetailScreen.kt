package com.burner.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun EventDetailScreen(
    eventId: String,
    onBackClick: () -> Unit,
    onGetTicketsClick: (String) -> Unit,
    viewModel: EventDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(eventId) {
        viewModel.loadEvent(eventId)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        if (uiState.isLoading) {
            LoadingView()
        } else if (uiState.event == null) {
            EmptyStateView(
                title = "EVENT NOT FOUND",
                subtitle = "This event may no longer be available",
                action = {
                    SecondaryButton(
                        text = "GO BACK",
                        onClick = onBackClick,
                        modifier = Modifier.width(200.dp)
                    )
                }
            )
        } else {
            val event = uiState.event!!

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // Hero image
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(300.dp)
                ) {
                    AsyncImage(
                        model = event.imageUrl,
                        contentDescription = event.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )

                    // Gradient overlay
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.verticalGradient(
                                    colors = listOf(
                                        Color.Transparent,
                                        BurnerColors.Background
                                    ),
                                    startY = 150f
                                )
                            )
                    )

                    // Back button
                    IconButton(
                        onClick = onBackClick,
                        modifier = Modifier
                            .padding(BurnerDimensions.spacingLg)
                            .statusBarsPadding()
                    ) {
                        Icon(
                            imageVector = Icons.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = BurnerColors.White
                        )
                    }

                    // Bookmark button
                    IconButton(
                        onClick = { viewModel.toggleBookmark() },
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(BurnerDimensions.spacingLg)
                            .statusBarsPadding()
                    ) {
                        Icon(
                            imageVector = if (uiState.isBookmarked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                            contentDescription = "Bookmark",
                            tint = if (uiState.isBookmarked) Color.Red else BurnerColors.White
                        )
                    }
                }

                // Content
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(BurnerDimensions.paddingScreen)
                ) {
                    // Venue
                    Text(
                        text = event.venue.uppercase(),
                        style = BurnerTypography.label,
                        color = BurnerColors.TextSecondary
                    )

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

                    // Event name
                    Text(
                        text = event.name,
                        style = BurnerTypography.pageHeader,
                        color = BurnerColors.White
                    )

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

                    // Date and time
                    event.startDate?.let { date ->
                        InfoRow(
                            icon = Icons.Filled.CalendarToday,
                            title = formatDate(date),
                            subtitle = formatTime(date, event.endDate)
                        )
                    }

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                    // Location
                    InfoRow(
                        icon = Icons.Filled.LocationOn,
                        title = event.venue,
                        subtitle = "View on map"
                    )

                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

                    // Price
                    InfoRow(
                        icon = Icons.Filled.ConfirmationNumber,
                        title = if (event.isSoldOut) "SOLD OUT" else "From £${String.format("%.2f", event.price)}",
                        subtitle = if (event.isSoldOut) "" else "${event.ticketsRemaining} tickets remaining"
                    )

                    // Tags
                    if (!event.tags.isNullOrEmpty()) {
                        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

                        Row(
                            horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm)
                        ) {
                            event.tags.take(3).forEach { tag ->
                                Text(
                                    text = tag.uppercase(),
                                    style = BurnerTypography.caption,
                                    color = BurnerColors.TextSecondary,
                                    modifier = Modifier
                                        .background(
                                            BurnerColors.CardBackground,
                                            RoundedCornerShape(BurnerDimensions.radiusSm)
                                        )
                                        .padding(
                                            horizontal = BurnerDimensions.spacingSm,
                                            vertical = BurnerDimensions.spacingXs
                                        )
                                )
                            }
                        }
                    }

                    // Description
                    if (!event.description.isNullOrBlank()) {
                        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

                        Text(
                            text = "ABOUT",
                            style = BurnerTypography.label,
                            color = BurnerColors.TextSecondary
                        )

                        Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

                        Text(
                            text = event.description,
                            style = BurnerTypography.body,
                            color = BurnerColors.TextTertiary
                        )
                    }

                    // Burner Mode placeholder
                    Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

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
                                text = "Go offline and be present at this event",
                                style = BurnerTypography.secondary,
                                color = BurnerColors.TextTertiary
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(100.dp)) // Space for bottom button
                }
            }

            // Bottom action button
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(Color.Transparent, BurnerColors.Background),
                            startY = 0f
                        )
                    )
                    .padding(BurnerDimensions.paddingScreen)
                    .navigationBarsPadding()
            ) {
                PrimaryButton(
                    text = if (event.isSoldOut) "SOLD OUT" else "GET TICKETS",
                    onClick = { event.id?.let { onGetTicketsClick(it) } },
                    enabled = !event.isSoldOut
                )
            }
        }
    }
}

@Composable
private fun InfoRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = BurnerColors.White,
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(BurnerDimensions.spacingMd))

        Column {
            Text(
                text = title,
                style = BurnerTypography.body,
                color = BurnerColors.White
            )
            if (subtitle.isNotBlank()) {
                Text(
                    text = subtitle,
                    style = BurnerTypography.secondary,
                    color = BurnerColors.TextSecondary
                )
            }
        }
    }
}

private fun formatDate(date: Date): String {
    val format = SimpleDateFormat("EEEE, d MMMM yyyy", Locale.getDefault())
    return format.format(date)
}

private fun formatTime(start: Date, end: Date?): String {
    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
    val startTime = timeFormat.format(start)
    return if (end != null) {
        "$startTime - ${timeFormat.format(end)}"
    } else {
        startTime
    }
}
