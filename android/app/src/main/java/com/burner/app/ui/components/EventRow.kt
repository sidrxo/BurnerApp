package com.burner.app.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.burner.app.data.models.Event
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

/**
 * Event Row component matching iOS EventRow
 * Horizontal row with thumbnail, details, and bookmark button
 */
@Composable
fun EventRow(
    event: Event,
    isBookmarked: Boolean = false,
    onBookmarkClick: ((Event) -> Unit)? = null,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    distanceText: String? = null,
    showBookmark: Boolean = true
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Event image (60x60 like iOS)
        AsyncImage(
            model = event.imageUrl,
            contentDescription = event.name,
            modifier = Modifier
                .size(60.dp)
                .clip(RoundedCornerShape(8.dp)),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.width(12.dp))

        // Event details
        Column(
            modifier = Modifier.weight(1f)
        ) {
            // Event name
            Text(
                text = event.name,
                style = BurnerTypography.body,
                color = BurnerColors.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(4.dp))

            // Venue and distance row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = event.venue,
                    style = BurnerTypography.secondary,
                    color = BurnerColors.TextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false)
                )

                // Distance (if available)
                if (distanceText != null) {
                    Spacer(modifier = Modifier.width(8.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Filled.LocationOn,
                            contentDescription = null,
                            tint = BurnerColors.TextSecondary,
                            modifier = Modifier.size(12.dp)
                        )
                        Spacer(modifier = Modifier.width(2.dp))
                        Text(
                            text = distanceText,
                            style = BurnerTypography.caption,
                            color = BurnerColors.TextSecondary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Date
            event.startDate?.let { date ->
                Text(
                    text = formatDateShort(date),
                    style = BurnerTypography.secondary,
                    color = BurnerColors.TextSecondary
                )
            }
        }

        // Bookmark button
        if (showBookmark && onBookmarkClick != null) {
            IconButton(
                onClick = { onBookmarkClick(event) },
                modifier = Modifier.size(36.dp)
            ) {
                Icon(
                    imageVector = if (isBookmarked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                    contentDescription = "Bookmark",
                    tint = if (isBookmarked) BurnerColors.White else BurnerColors.TextSecondary,
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

private fun formatDateShort(date: Date): String {
    val format = SimpleDateFormat("EEE, d MMM", Locale.getDefault())
    return format.format(date)
}
