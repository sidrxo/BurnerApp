package com.burner.app.ui.screens.bookmarks

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.burner.app.data.models.Bookmark
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun BookmarksScreen(
    onEventClick: (String) -> Unit,
    onSignInClick: () -> Unit,
    viewModel: BookmarksViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Header
        BurnerTopBar(title = "SAVES")

        if (!uiState.isAuthenticated) {
            // Not signed in
            EmptyStateView(
                title = "SIGN IN TO SAVE",
                subtitle = "Create an account to save events for later",
                icon = Icons.Outlined.BookmarkBorder,
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
        } else if (uiState.bookmarks.isEmpty()) {
            EmptyStateView(
                title = "SAVE FOR LATER",
                subtitle = "Tap the heart icon on events you love",
                icon = Icons.Outlined.BookmarkBorder
            )
        } else {
            // Bookmarked events list
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(
                    horizontal = BurnerDimensions.paddingScreen,
                    vertical = BurnerDimensions.spacingSm
                ),
                verticalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm)
            ) {
                items(uiState.bookmarks, key = { it.eventId }) { bookmark ->
                    BookmarkCard(
                        bookmark = bookmark,
                        onClick = { onEventClick(bookmark.eventId) },
                        onRemove = { viewModel.removeBookmark(bookmark.eventId) }
                    )
                }
            }
        }
    }
}

@Composable
private fun BookmarkCard(
    bookmark: Bookmark,
    onClick: () -> Unit,
    onRemove: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(BurnerDimensions.cardHeightLg)
            .clip(RoundedCornerShape(BurnerDimensions.radiusMd))
            .clickable(onClick = onClick)
    ) {
        // Background image
        AsyncImage(
            model = bookmark.eventImageUrl,
            contentDescription = bookmark.eventName,
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
                            Color.Black.copy(alpha = 0.8f)
                        ),
                        startY = 100f
                    )
                )
        )

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(BurnerDimensions.paddingCard),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Top row with remove button
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Date chip
                bookmark.startDate?.let { date ->
                    BookmarkDateChip(date = date)
                }

                // Remove button
                IconButton(
                    onClick = onRemove,
                    modifier = Modifier.size(36.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Favorite,
                        contentDescription = "Remove",
                        tint = Color.Red
                    )
                }
            }

            // Bottom content
            Column {
                // Venue
                Text(
                    text = bookmark.eventVenue.uppercase(),
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextSecondary
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXs))

                // Event name
                Text(
                    text = bookmark.eventName,
                    style = BurnerTypography.card,
                    color = BurnerColors.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

                // Price
                Text(
                    text = "From £${String.format("%.2f", bookmark.eventPrice)}",
                    style = BurnerTypography.secondary,
                    color = BurnerColors.White
                )
            }
        }
    }
}

@Composable
private fun BookmarkDateChip(date: Date) {
    val dayFormat = SimpleDateFormat("dd", Locale.getDefault())
    val monthFormat = SimpleDateFormat("MMM", Locale.getDefault())

    Column(
        modifier = Modifier
            .background(
                color = BurnerColors.Black.copy(alpha = 0.7f),
                shape = RoundedCornerShape(BurnerDimensions.radiusSm)
            )
            .padding(horizontal = BurnerDimensions.spacingSm, vertical = BurnerDimensions.spacingXs),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = dayFormat.format(date),
            style = BurnerTypography.body.copy(fontWeight = FontWeight.Bold),
            color = BurnerColors.White
        )
        Text(
            text = monthFormat.format(date).uppercase(),
            style = BurnerTypography.caption,
            color = BurnerColors.TextSecondary
        )
    }
}
