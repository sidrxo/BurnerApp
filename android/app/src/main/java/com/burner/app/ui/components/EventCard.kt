package com.burner.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.burner.app.data.models.Event
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun EventCard(
    event: Event,
    isBookmarked: Boolean = false,
    onBookmarkClick: ((Event) -> Unit)? = null,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = BurnerDimensions.cardHeightLg
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(RoundedCornerShape(BurnerDimensions.radiusMd))
            .clickable(onClick = onClick)
    ) {
        // Background image
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
            // Top row - Date and bookmark
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                // Date chip
                event.startDate?.let { date ->
                    DateChip(date = date)
                }

                // Bookmark button
                if (onBookmarkClick != null) {
                    IconButton(
                        onClick = { onBookmarkClick(event) },
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = if (isBookmarked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                            contentDescription = "Bookmark",
                            tint = if (isBookmarked) Color.Red else BurnerColors.White
                        )
                    }
                }
            }

            // Bottom content
            Column {
                // Venue
                Text(
                    text = event.venue.uppercase(),
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextSecondary
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingXs))

                // Event name
                Text(
                    text = event.name,
                    style = BurnerTypography.card,
                    color = BurnerColors.White,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

                // Price
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (event.isSoldOut) {
                        SoldOutBadge()
                    } else {
                        Text(
                            text = "From ",
                            style = BurnerTypography.secondary,
                            color = BurnerColors.TextSecondary
                        )
                        Text(
                            text = "£${String.format("%.2f", event.price)}",
                            style = BurnerTypography.secondary.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
                            color = BurnerColors.White
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DateChip(
    date: Date,
    modifier: Modifier = Modifier
) {
    val dayFormat = SimpleDateFormat("dd", Locale.getDefault())
    val monthFormat = SimpleDateFormat("MMM", Locale.getDefault())

    Column(
        modifier = modifier
            .background(
                color = BurnerColors.Black.copy(alpha = 0.7f),
                shape = RoundedCornerShape(BurnerDimensions.radiusSm)
            )
            .padding(horizontal = BurnerDimensions.spacingSm, vertical = BurnerDimensions.spacingXs),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = dayFormat.format(date),
            style = BurnerTypography.body.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold),
            color = BurnerColors.White
        )
        Text(
            text = monthFormat.format(date).uppercase(),
            style = BurnerTypography.caption,
            color = BurnerColors.TextSecondary
        )
    }
}

@Composable
fun SoldOutBadge(
    modifier: Modifier = Modifier
) {
    Text(
        text = "SOLD OUT",
        style = BurnerTypography.label,
        color = BurnerColors.Error,
        modifier = modifier
            .background(
                color = BurnerColors.Error.copy(alpha = 0.2f),
                shape = RoundedCornerShape(BurnerDimensions.radiusXs)
            )
            .padding(horizontal = BurnerDimensions.spacingSm, vertical = BurnerDimensions.spacingXs)
    )
}

@Composable
fun FeaturedEventCard(
    event: Event,
    isBookmarked: Boolean = false,
    onBookmarkClick: ((Event) -> Unit)? = null,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    EventCard(
        event = event,
        isBookmarked = isBookmarked,
        onBookmarkClick = onBookmarkClick,
        onClick = onClick,
        modifier = modifier,
        height = BurnerDimensions.cardHeightFeatured
    )
}
