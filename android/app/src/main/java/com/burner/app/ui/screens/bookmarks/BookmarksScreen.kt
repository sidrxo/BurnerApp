package com.burner.app.ui.screens.bookmarks

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import coil.compose.AsyncImage
import com.burner.shared.models.Event
import com.burner.app.ui.components.PrimaryButton
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun BookmarksScreen(
    onEventClick: (String) -> Unit,
    onExploreClick: () -> Unit,
    onSignInClick: () -> Unit,
    viewModel: BookmarksViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val bookmarks = uiState.bookmarkedEvents
    val lifecycleOwner = LocalLifecycleOwner.current

    // FIX: Force refresh data whenever the screen becomes visible (ON_RESUME)
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                // Assuming the user is authenticated, refresh the list
                if (uiState.isAuthenticated) {
                    viewModel.loadBookmarks()
                }
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BookmarksHeader()

        if (!uiState.isAuthenticated) {
            BookmarksSignedOutState(onSignInClick)
        } else if (uiState.isLoading && bookmarks.isEmpty()) {
            // Optional: Simple loading indicator if mostly empty
            // You can implement a custom LoadingView here if desired
            BookmarksEmptyState(onExploreClick)
        } else if (bookmarks.isEmpty()) {
            BookmarksEmptyState(onExploreClick)
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 100.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(
                    items = bookmarks,
                    key = { event -> event.id ?: UUID.randomUUID().toString() }
                ) { event: Event ->

                    val rowModifier = Modifier
                        .padding(horizontal = 16.dp)
                        .animateItemPlacement(
                            animationSpec = spring(
                                stiffness = Spring.StiffnessLow,
                                dampingRatio = Spring.DampingRatioLowBouncy
                            )
                        )

                    BookmarkRow(
                        event = event,
                        onClick = { event.id?.let { onEventClick(it) } },
                        onUnbookmark = { viewModel.removeBookmark(event) },
                        modifier = rowModifier
                    )
                }
            }
        }
    }
}

@Composable
fun BookmarkRow(
    event: Event,
    onClick: () -> Unit,
    onUnbookmark: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(80.dp)
            .clickable(onClick = onClick)
            .background(BurnerColors.Background),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Thumbnail
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(BurnerColors.CardBackground)
        ) {
            val imageUrl = event.imageUrl
            if (!imageUrl.isNullOrEmpty()) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }
        }

        Spacer(modifier = Modifier.width(16.dp))

        // Info
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = event.name ?: "",
                style = BurnerTypography.body,
                color = BurnerColors.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            val dateString = remember(event.startTime) { safeFormatDate(event.startTime) }
            if (dateString.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = dateString,
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextSecondary
                )
            }

            val venue = event.venue
            if (!venue.isNullOrEmpty()) {
                Text(
                    text = venue,
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextSecondary,
                    maxLines = 1
                )
            }
        }

        // Bookmark Action
        IconButton(onClick = onUnbookmark) {
            Icon(
                imageVector = Icons.Filled.Bookmark,
                contentDescription = "Remove Bookmark",
                tint = BurnerColors.White
            )
        }
    }
}

private fun safeFormatDate(dateObj: Any?): String {
    if (dateObj == null) return ""

    return try {
        val date: Date? = when (dateObj) {
            is Date -> dateObj
            is String -> {
                try {
                    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).parse(dateObj)
                } catch (e: Exception) {
                    null
                }
            }
            else -> null
        }

        if (date != null) {
            SimpleDateFormat("MMM d, h:mm a", Locale.getDefault()).format(date)
        } else {
            ""
        }
    } catch (e: Exception) {
        ""
    }
}

@Composable
private fun BookmarksHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 14.dp, bottom = 20.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Saves",
            style = BurnerTypography.pageHeader,
            color = BurnerColors.White
        )

        Spacer(modifier = Modifier.size(38.dp))
    }
}

@Composable
private fun BookmarksEmptyState(onExploreClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(bottom = 100.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Filled.Bookmark,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = BurnerColors.TextDimmed
        )

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "SAVE FOR LATER",
            style = BurnerTypography.sectionHeader,
            color = BurnerColors.White
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Tap the bookmark icon on any event\nto save it here.",
            style = BurnerTypography.card,
            color = BurnerColors.TextSecondary,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        PrimaryButton(
            text = "BROWSE EVENTS",
            onClick = onExploreClick,
            modifier = Modifier.width(200.dp)
        )
    }
}

@Composable
private fun BookmarksSignedOutState(onSignInClick: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Sign in to see your saves",
            style = BurnerTypography.body,
            color = BurnerColors.TextSecondary
        )
        Spacer(modifier = Modifier.height(16.dp))
        PrimaryButton(text = "SIGN IN", onClick = onSignInClick)
    }
}