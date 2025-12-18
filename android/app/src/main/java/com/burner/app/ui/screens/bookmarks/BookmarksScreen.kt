package com.burner.app.ui.screens.bookmarks

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun BookmarksScreen(
    onEventClick: (String) -> Unit,
    onSignInClick: () -> Unit,
    onExploreClick: () -> Unit = {},
    viewModel: BookmarksViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // FIX: Force a refresh when the screen appears.
    // This ensures that new bookmarks added from Explore/Detail screens appear immediately.
    LaunchedEffect(Unit) {
        viewModel.loadBookmarks()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Header matching iOS
        BookmarksHeader()

        when {
            !uiState.isAuthenticated -> {
                // Not implemented - bookmarks require auth but showing empty state
                EmptyBookmarksState(onBrowseClick = onExploreClick)
            }
            uiState.isLoading -> {
                LoadingState()
            }
            uiState.bookmarkedEvents.isEmpty() -> {
                EmptyBookmarksState(onBrowseClick = onExploreClick)
            }
            else -> {
                BookmarksList(
                    events = uiState.bookmarkedEvents,
                    onEventClick = onEventClick,
                    onBookmarkClick = { viewModel.toggleBookmark(it) }
                )
            }
        }
    }
}

@Composable
private fun BookmarksHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .padding(top = 14.dp, bottom = 30.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Saves",
            style = BurnerTypography.pageHeader,
            color = BurnerColors.White,
            modifier = Modifier.padding(bottom = 2.dp)
        )

        // Empty spacer for symmetry (matching iOS)
        Box(modifier = Modifier.size(38.dp))
    }
}

@Composable
private fun LoadingState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(32.dp),
                color = BurnerColors.White,
                strokeWidth = 2.dp
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Loading bookmarks...",
                style = BurnerTypography.body,
                color = BurnerColors.TextSecondary
            )
        }
    }
}

@Composable
private fun EmptyBookmarksState(onBrowseClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(bottom = 100.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Bookmark icon placeholder
            Box(
                modifier = Modifier
                    .size(140.dp)
                    .padding(bottom = 30.dp)
            )

            Text(
                text = "SAVE FOR",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White
            )
            Text(
                text = "LATER",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Tap the heart on any event to save it here.",
                style = BurnerTypography.card,
                color = BurnerColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(20.dp))

            PrimaryButton(
                text = "BROWSE EVENTS",
                onClick = onBrowseClick,
                modifier = Modifier.width(200.dp)
            )
        }
    }
}

@Composable
private fun BookmarksList(
    events: List<com.burner.app.data.models.Event>,
    onEventClick: (String) -> Unit,
    onBookmarkClick: (com.burner.app.data.models.Event) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 100.dp)
    ) {
        items(events, key = { it.id ?: "" }) { event ->
            EventRow(
                event = event,
                isBookmarked = true, // All items here are bookmarked
                onBookmarkClick = onBookmarkClick,
                onClick = { event.id?.let { onEventClick(it) } }
            )
        }
    }
}