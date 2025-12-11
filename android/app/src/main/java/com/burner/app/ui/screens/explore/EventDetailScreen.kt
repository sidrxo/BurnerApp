package com.burner.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
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

            // Calculate dynamic hero height (matching iOS: 50% screen height, 350-550dp range)
            val configuration = LocalConfiguration.current
            val screenHeight = configuration.screenHeightDp.dp
            val heroHeight = (screenHeight * 0.50f).coerceIn(350.dp, 550.dp)

            Box(modifier = Modifier.fillMaxSize()) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                ) {
                    // Header with back button
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp)
                    ) {
                        IconButton(
                            onClick = onBackClick,
                            modifier = Modifier
                                .padding(horizontal = BurnerDimensions.spacingLg)
                                .statusBarsPadding()
                        ) {
                            Icon(
                                imageVector = Icons.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = BurnerColors.White
                            )
                        }
                    }

                    // Hero image with blurred background (matching iOS)
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(heroHeight + 52.dp) // heroHeight + top(24dp) + bottom(28dp)
                            .padding(top = 24.dp, bottom = 28.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        // Blurred background (90% of hero height, matching iOS)
                        AsyncImage(
                            model = event.imageUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(heroHeight * 0.9f)
                                .blur(40.dp)
                                .alpha(0.9f),
                            contentScale = ContentScale.Crop
                        )

                        // Main rounded image with border overlay (matching iOS)
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp)
                        ) {
                            AsyncImage(
                                model = event.imageUrl,
                                contentDescription = event.name,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(heroHeight)
                                    .clip(RoundedCornerShape(28.dp))
                                    .shadow(
                                        elevation = 18.dp,
                                        shape = RoundedCornerShape(28.dp),
                                        spotColor = Color.Black.copy(alpha = 0.3f)
                                    ),
                                contentScale = ContentScale.Crop
                            )

                            // White border overlay
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(heroHeight)
                                    .clip(RoundedCornerShape(28.dp))
                                    .background(Color.Transparent)
                                    .border(
                                        width = 1.dp,
                                        color = BurnerColors.White.copy(alpha = 0.08f),
                                        shape = RoundedCornerShape(28.dp)
                                    )
                            )
                        }
                    }

                    // Content (spacing handled by hero image bottom padding)
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp)
                    ) {
                        // Event name with bookmark and share buttons (matching iOS)
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = event.name,
                                style = BurnerTypography.hero,
                                color = BurnerColors.White,
                                modifier = Modifier.weight(1f)
                            )

                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                // Bookmark button
                                IconButton(
                                    onClick = { viewModel.toggleBookmark() },
                                    modifier = Modifier
                                        .size(60.dp)
                                        .background(
                                            BurnerColors.White.copy(alpha = 0.1f),
                                            RoundedCornerShape(10.dp)
                                        )
                                ) {
                                    Icon(
                                        imageVector = if (uiState.isBookmarked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                                        contentDescription = "Bookmark",
                                        tint = BurnerColors.White
                                    )
                                }

                                // Share button
                                IconButton(
                                    onClick = { /* TODO: Implement share */ },
                                    modifier = Modifier
                                        .size(60.dp)
                                        .background(
                                            BurnerColors.White.copy(alpha = 0.1f),
                                            RoundedCornerShape(10.dp)
                                        )
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.Share,
                                        contentDescription = "Share",
                                        tint = BurnerColors.White
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(24.dp))

                        // About section (matching iOS)
                        if (!event.description.isNullOrBlank()) {
                            Column(
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Text(
                                    text = "About",
                                    style = BurnerTypography.body,
                                    color = BurnerColors.White
                                )

                                Text(
                                    text = event.description,
                                    style = BurnerTypography.body,
                                    color = BurnerColors.TextSecondary,
                                    maxLines = Int.MAX_VALUE
                                )
                            }

                            Spacer(modifier = Modifier.height(16.dp))
                        }

                        // Event Details section (matching iOS)
                        Column(
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                text = "Event Details",
                                style = BurnerTypography.body,
                                color = BurnerColors.White
                            )

                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                // Date
                                event.startDate?.let { date ->
                                    EventDetailRow(
                                        icon = "calendar",
                                        title = "Date",
                                        value = formatFullDate(date)
                                    )
                                }

                                // Time
                                event.startDate?.let { date ->
                                    EventDetailRow(
                                        icon = "clock",
                                        title = "Time",
                                        value = formatTime(date, event.endDate)
                                    )
                                }

                                // Venue
                                EventDetailRow(
                                    icon = "location",
                                    title = "Venue",
                                    value = event.venue
                                )

                                // Price
                                EventDetailRow(
                                    icon = "creditcard",
                                    title = "Price",
                                    value = "£${String.format("%.2f", event.price)}"
                                )

                                // Genre (Tags)
                                if (!event.tags.isNullOrEmpty()) {
                                    EventDetailRow(
                                        icon = "tag",
                                        title = "Genre",
                                        value = event.tags.joinToString(", ")
                                    )
                                }
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
}

// EventDetailRow matching iOS design with icons and vertical layout
@Composable
private fun EventDetailRow(
    icon: String,
    title: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                BurnerColors.TextSecondary.copy(alpha = 0.1f),
                RoundedCornerShape(8.dp)
            )
            .padding(horizontal = 12.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.Start,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Icon
        Icon(
            imageVector = when (icon) {
                "calendar" -> Icons.Filled.DateRange
                "clock" -> Icons.Filled.Schedule
                "location" -> Icons.Filled.LocationOn
                "creditcard" -> Icons.Filled.CreditCard
                "tag" -> Icons.Filled.Label
                else -> Icons.Filled.Info
            },
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = BurnerColors.White
        )

        Spacer(modifier = Modifier.width(12.dp))

        // Title and Value in vertical stack
        Column(
            verticalArrangement = Arrangement.spacedBy(1.dp)
        ) {
            Text(
                text = title,
                style = BurnerTypography.secondary,
                color = BurnerColors.TextSecondary
            )

            Text(
                text = value,
                style = BurnerTypography.body,
                color = BurnerColors.White,
                maxLines = 2
            )
        }

        Spacer(modifier = Modifier.weight(1f))
    }
}

private fun formatDate(date: Date): String {
    val formatter = SimpleDateFormat("EEE d MMM", Locale.getDefault())
    return formatter.format(date)
}

private fun formatFullDate(date: Date): String {
    val formatter = SimpleDateFormat("E d MMM yyyy", Locale.getDefault())
    return formatter.format(date)
}

private fun formatTime(startDate: Date, endDate: Date?): String {
    val formatter = SimpleDateFormat("h:mm a", Locale.getDefault())
    val startTime = formatter.format(startDate)

    return if (endDate != null) {
        val endTime = formatter.format(endDate)
        "$startTime - $endTime"
    } else {
        startTime
    }
}
