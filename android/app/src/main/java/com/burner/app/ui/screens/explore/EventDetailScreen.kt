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

                // Content - Matching iOS order exactly
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                ) {
                    // Event name (matching iOS - no venue label above)
                    Text(
                        text = event.name,
                        style = BurnerTypography.hero,
                        color = BurnerColors.White
                    )

                    Spacer(modifier = Modifier.height(24.dp))

                    // About section (iOS shows this first if it exists)
                    if (!event.description.isNullOrBlank()) {
                        Text(
                            text = "About",
                            style = BurnerTypography.body,
                            color = BurnerColors.White
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = event.description,
                            style = BurnerTypography.secondary,
                            color = BurnerColors.TextSecondary
                        )

                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    // Event Details section (matching iOS)
                    Text(
                        text = "Event Details",
                        style = BurnerTypography.body,
                        color = BurnerColors.White
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Column(modifier = Modifier.fillMaxWidth()) {
                        // Date
                        event.startDate?.let { date ->
                            EventDetailRow(
                                icon = "calendar",
                                title = "Date",
                                value = formatDate(date)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                        }

                        // Time
                        event.startDate?.let { date ->
                            EventDetailRow(
                                icon = "clock",
                                title = "Time",
                                value = formatTime(date, event.endDate)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                        }

                        // Venue
                        EventDetailRow(
                            icon = "location",
                            title = "Venue",
                            value = event.venue
                        )
                        Spacer(modifier = Modifier.height(8.dp))

                        // Price
                        EventDetailRow(
                            icon = "creditcard",
                            title = "Price",
                            value = "£${String.format("%.2f", event.price)}"
                        )

                        // Genre (tags) - iOS shows this in Event Details if exists
                        if (!event.tags.isNullOrEmpty()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            EventDetailRow(
                                icon = "tag",
                                title = "Genre",
                                value = event.tags.joinToString(", ")
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(100.dp)) // Space for bottom button
                }
            }

            // Bottom action button (matching iOS 5-state system)
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
                    text = viewModel.getButtonText(),
                    onClick = { event.id?.let { onGetTicketsClick(it) } },
                    enabled = !viewModel.isButtonDisabled()
                )
            }
        }
    }
}

/**
 * Event Detail Row matching iOS EventDetailRow
 * Shows icon, title (label), and value in a structured row
 */
@Composable
private fun EventDetailRow(
    icon: String,
    title: String,
    value: String
) {
    val iconVector = when (icon) {
        "calendar" -> Icons.Filled.CalendarToday
        "clock" -> Icons.Filled.AccessTime
        "location" -> Icons.Filled.LocationOn
        "creditcard" -> Icons.Filled.CreditCard
        "tag" -> Icons.Filled.LocalOffer
        else -> Icons.Filled.Info
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                BurnerColors.White.copy(alpha = 0.05f),
                RoundedCornerShape(8.dp)
            )
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = iconVector,
            contentDescription = null,
            tint = BurnerColors.White,
            modifier = Modifier.size(20.dp)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = BurnerTypography.caption,
                color = BurnerColors.TextSecondary
            )
            Text(
                text = value,
                style = BurnerTypography.secondary,
                color = BurnerColors.White
            )
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
