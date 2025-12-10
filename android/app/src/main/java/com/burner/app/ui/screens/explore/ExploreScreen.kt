package com.burner.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExploreScreen(
    onEventClick: (String) -> Unit,
    onSettingsClick: () -> Unit,
    onLocationClick: (() -> Unit)? = null,
    viewModel: ExploreViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val pullToRefreshState = rememberPullToRefreshState()

    LaunchedEffect(pullToRefreshState.isRefreshing) {
        if (pullToRefreshState.isRefreshing) {
            viewModel.refresh()
            delay(1000)
            pullToRefreshState.endRefresh()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
            .nestedScroll(pullToRefreshState.nestedScrollConnection)
    ) {
        if (uiState.isLoading && uiState.allEvents.isEmpty()) {
            LoadingView()
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 80.dp)
            ) {
                // Header - matching iOS "Explore" header
                item {
                    ExploreHeader(
                        hasLocation = uiState.userLat != null && uiState.userLon != null,
                        onLocationClick = onLocationClick,
                        onSettingsClick = onSettingsClick
                    )
                }

                // First Featured Hero Card (like iOS)
                if (uiState.featuredEvents.isNotEmpty()) {
                    item {
                        FeaturedHeroCard(
                            event = uiState.featuredEvents[0],
                            isBookmarked = uiState.bookmarkedEventIds.contains(uiState.featuredEvents[0].id),
                            onBookmarkClick = { viewModel.toggleBookmark(it) },
                            onClick = { uiState.featuredEvents[0].id?.let { onEventClick(it) } },
                            modifier = Modifier
                                .padding(horizontal = 10.dp)
                                .padding(bottom = 40.dp)
                        )
                    }
                }

                // Popular Events Section (like iOS)
                if (uiState.popularEvents.isNotEmpty()) {
                    item {
                        EventSectionHeader(title = "Popular")
                    }

                    items(uiState.popularEvents, key = { "popular_${it.id}" }) { event ->
                        EventRow(
                            event = event,
                            isBookmarked = uiState.bookmarkedEventIds.contains(event.id),
                            onBookmarkClick = { viewModel.toggleBookmark(it) },
                            onClick = { event.id?.let { onEventClick(it) } }
                        )
                    }

                    item {
                        Spacer(modifier = Modifier.height(40.dp))
                    }
                }

                // This Week Section
                if (uiState.thisWeekEvents.isNotEmpty()) {
                    item {
                        EventSectionHeader(title = "This Week")
                    }

                    items(uiState.thisWeekEvents, key = { "thisweek_${it.id}" }) { event ->
                        EventRow(
                            event = event,
                            isBookmarked = uiState.bookmarkedEventIds.contains(event.id),
                            onBookmarkClick = { viewModel.toggleBookmark(it) },
                            onClick = { event.id?.let { onEventClick(it) } }
                        )
                    }

                    item {
                        Spacer(modifier = Modifier.height(40.dp))
                    }
                }

                // Second Featured Hero Card (if available, like iOS pattern)
                if (uiState.featuredEvents.size > 1) {
                    item {
                        FeaturedHeroCard(
                            event = uiState.featuredEvents[1],
                            isBookmarked = uiState.bookmarkedEventIds.contains(uiState.featuredEvents[1].id),
                            onBookmarkClick = { viewModel.toggleBookmark(it) },
                            onClick = { uiState.featuredEvents[1].id?.let { onEventClick(it) } },
                            modifier = Modifier
                                .padding(horizontal = 10.dp)
                                .padding(bottom = 40.dp)
                        )
                    }
                }

                // Nearby Section (with distance like iOS)
                if (uiState.nearbyEvents.isNotEmpty() && uiState.userLat != null && uiState.userLon != null) {
                    item {
                        EventSectionHeader(title = "Nearby")
                    }

                    items(uiState.nearbyEvents, key = { "nearby_${it.id}" }) { event ->
                        val distance = event.distanceFrom(uiState.userLat!!, uiState.userLon!!)
                        EventRow(
                            event = event,
                            isBookmarked = uiState.bookmarkedEventIds.contains(event.id),
                            onBookmarkClick = { viewModel.toggleBookmark(it) },
                            onClick = { event.id?.let { onEventClick(it) } },
                            distanceText = distance?.let { viewModel.formatDistance(it) }
                        )
                    }

                    item {
                        Spacer(modifier = Modifier.height(40.dp))
                    }
                }

                // Third Featured Hero Card (if available)
                if (uiState.featuredEvents.size > 2) {
                    item {
                        FeaturedHeroCard(
                            event = uiState.featuredEvents[2],
                            isBookmarked = uiState.bookmarkedEventIds.contains(uiState.featuredEvents[2].id),
                            onBookmarkClick = { viewModel.toggleBookmark(it) },
                            onClick = { uiState.featuredEvents[2].id?.let { onEventClick(it) } },
                            modifier = Modifier
                                .padding(horizontal = 10.dp)
                                .padding(bottom = 40.dp)
                        )
                    }
                }

                // Empty state
                if (uiState.allEvents.isEmpty() && !uiState.isLoading) {
                    item {
                        EmptyStateView(
                            title = "No Events",
                            subtitle = "Check back later for upcoming events",
                            modifier = Modifier.height(300.dp)
                        )
                    }
                }
            }
        }

        PullToRefreshContainer(
            state = pullToRefreshState,
            modifier = Modifier.align(Alignment.TopCenter),
            containerColor = BurnerColors.Surface,
            contentColor = BurnerColors.White
        )
    }
}

/**
 * Explore Header matching iOS ExploreView header
 */
@Composable
private fun ExploreHeader(
    hasLocation: Boolean,
    onLocationClick: (() -> Unit)?,
    onSettingsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .padding(top = 14.dp, bottom = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // "Explore" title - matching iOS appPageHeader style
        Text(
            text = "Explore",
            style = BurnerTypography.pageHeader.copy(
                letterSpacing = (-1.5).sp
            ),
            color = BurnerColors.White
        )

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Location button (like iOS map icon)
            if (onLocationClick != null) {
                IconButton(
                    onClick = onLocationClick,
                    modifier = Modifier
                        .size(38.dp)
                        .alpha(if (hasLocation) 1f else 0.3f)
                ) {
                    Icon(
                        imageVector = Icons.Filled.LocationOn,
                        contentDescription = "Set Location",
                        tint = BurnerColors.White,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            // Settings button
            IconButton(
                onClick = onSettingsClick,
                modifier = Modifier.size(38.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Settings,
                    contentDescription = "Settings",
                    tint = BurnerColors.White,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}

/**
 * Event Section Header matching iOS style
 */
@Composable
private fun EventSectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    onViewAll: (() -> Unit)? = null
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .padding(bottom = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = BurnerTypography.sectionHeader,
            color = BurnerColors.White
        )

        if (onViewAll != null) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .background(
                        color = BurnerColors.TextSecondary.copy(alpha = 0.3f),
                        shape = CircleShape
                    )
                    .clickable(onClick = onViewAll),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = ">",
                    style = BurnerTypography.body,
                    color = BurnerColors.TextSecondary
                )
            }
        }
    }
}
