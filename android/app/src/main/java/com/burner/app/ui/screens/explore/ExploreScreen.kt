package com.burner.app.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
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
        if (uiState.isLoading && uiState.featuredEvents.isEmpty()) {
            LoadingView()
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = BurnerDimensions.spacingXxl)
            ) {
                // Header
                item {
                    BurnerTopBar(
                        title = "BURNER",
                        onSettingsClick = onSettingsClick
                    )
                }

                // Featured Events
                if (uiState.featuredEvents.isNotEmpty()) {
                    item {
                        SectionHeader(
                            title = "FEATURED",
                            modifier = Modifier.padding(top = BurnerDimensions.spacingLg)
                        )
                    }

                    item {
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = BurnerDimensions.paddingScreen),
                            horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingMd),
                            modifier = Modifier.padding(top = BurnerDimensions.spacingSm)
                        ) {
                            items(uiState.featuredEvents, key = { it.id ?: "" }) { event ->
                                FeaturedEventCard(
                                    event = event,
                                    isBookmarked = uiState.bookmarkedEventIds.contains(event.id),
                                    onBookmarkClick = { viewModel.toggleBookmark(it) },
                                    onClick = { event.id?.let { onEventClick(it) } },
                                    modifier = Modifier.width(BurnerDimensions.cardHeightFeatured)
                                )
                            }
                        }
                    }
                }

                // This Week
                if (uiState.thisWeekEvents.isNotEmpty()) {
                    item {
                        SectionHeader(
                            title = "THIS WEEK",
                            modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
                        )
                    }

                    items(uiState.thisWeekEvents, key = { it.id ?: "" }) { event ->
                        EventCard(
                            event = event,
                            isBookmarked = uiState.bookmarkedEventIds.contains(event.id),
                            onBookmarkClick = { viewModel.toggleBookmark(it) },
                            onClick = { event.id?.let { onEventClick(it) } },
                            modifier = Modifier
                                .padding(horizontal = BurnerDimensions.paddingScreen)
                                .padding(top = BurnerDimensions.spacingSm)
                        )
                    }
                }

                // Nearby Events
                if (uiState.nearbyEvents.isNotEmpty()) {
                    item {
                        SectionHeader(
                            title = "NEARBY",
                            modifier = Modifier.padding(top = BurnerDimensions.spacingXl)
                        )
                    }

                    item {
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = BurnerDimensions.paddingScreen),
                            horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingMd),
                            modifier = Modifier.padding(top = BurnerDimensions.spacingSm)
                        ) {
                            items(uiState.nearbyEvents, key = { it.id ?: "" }) { event ->
                                EventCard(
                                    event = event,
                                    isBookmarked = uiState.bookmarkedEventIds.contains(event.id),
                                    onBookmarkClick = { viewModel.toggleBookmark(it) },
                                    onClick = { event.id?.let { onEventClick(it) } },
                                    modifier = Modifier.width(200.dp),
                                    height = BurnerDimensions.cardHeightMd
                                )
                            }
                        }
                    }
                }

                // Empty state
                if (uiState.featuredEvents.isEmpty() &&
                    uiState.thisWeekEvents.isEmpty() &&
                    uiState.nearbyEvents.isEmpty() &&
                    !uiState.isLoading) {
                    item {
                        EmptyStateView(
                            title = "NO EVENTS",
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
