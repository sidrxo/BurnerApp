package com.burner.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.burner.app.data.models.Event
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

/**
 * Featured Hero Card matching iOS FeaturedHeroCard
 * Full-width card with image, blur effect, and event details
 */
@Composable
fun FeaturedHeroCard(
    event: Event,
    isBookmarked: Boolean = false,
    onBookmarkClick: ((Event) -> Unit)? = null,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val cardHeight = 420.dp

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(cardHeight)
            .clip(RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
    ) {
        // Background image
        AsyncImage(
            model = event.imageUrl,
            contentDescription = event.name,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )

        // Gradient overlay (matching iOS)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.1f),
                            Color.Black.copy(alpha = 0.6f)
                        ),
                        startY = 0f,
                        endY = Float.MAX_VALUE
                    )
                )
        )

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Top row - FEATURED badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                Text(
                    text = "FEATURED",
                    style = BurnerTypography.caption.copy(
                        letterSpacing = 1.5.sp
                    ),
                    color = BurnerColors.White,
                    modifier = Modifier
                        .background(
                            color = Color.Black.copy(alpha = 0.6f),
                            shape = CircleShape
                        )
                        .padding(horizontal = 10.dp, vertical = 5.dp)
                )
            }

            // Bottom content
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Bottom
            ) {
                // Event details
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    // Event name (uppercase, large)
                    Text(
                        text = event.name.uppercase(),
                        style = BurnerTypography.hero.copy(
                            fontWeight = FontWeight.Bold,
                            letterSpacing = (-1.5).sp
                        ),
                        color = BurnerColors.White,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Date and venue
                    event.startDate?.let { date ->
                        Text(
                            text = "${formatDateLong(date)} • ${event.venue}",
                            style = BurnerTypography.body,
                            color = BurnerColors.White.copy(alpha = 0.9f)
                        )
                    } ?: Text(
                        text = "- • ${event.venue}",
                        style = BurnerTypography.body,
                        color = BurnerColors.White.copy(alpha = 0.9f)
                    )

                    // Price
                    Text(
                        text = "£${String.format("%.2f", event.price)}",
                        style = BurnerTypography.body,
                        color = BurnerColors.White
                    )
                }

                // Bookmark button
                if (onBookmarkClick != null) {
                    IconButton(
                        onClick = { onBookmarkClick(event) },
                        modifier = Modifier.size(48.dp)
                    ) {
                        Icon(
                            imageVector = if (isBookmarked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                            contentDescription = "Bookmark",
                            tint = if (isBookmarked) BurnerColors.White else BurnerColors.White.copy(alpha = 0.7f),
                            modifier = Modifier.size(28.dp)
                        )
                    }
                }
            }
        }
    }
}

private fun formatDateLong(date: Date): String {
    val format = SimpleDateFormat("EEE d MMM", Locale.getDefault())
    return format.format(date)
}
