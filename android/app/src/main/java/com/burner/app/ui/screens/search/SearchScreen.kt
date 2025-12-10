package com.burner.app.ui.screens.search

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.platform.LocalFocusManager
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.data.repository.SearchSortOption
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun SearchScreen(
    onEventClick: (String) -> Unit,
    viewModel: SearchViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val focusRequester = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Header
        BurnerTopBar(title = "SEARCH")

        // Search field
        SearchField(
            value = uiState.searchQuery,
            onValueChange = viewModel::updateSearchQuery,
            onSearch = {
                focusManager.clearFocus()
                viewModel.search()
            },
            placeholder = "Search events, venues...",
            focusRequester = focusRequester,
            modifier = Modifier.padding(horizontal = BurnerDimensions.paddingScreen)
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

        // Sort options
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = BurnerDimensions.paddingScreen),
            horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm)
        ) {
            SearchSortOption.values().forEach { option ->
                ChipButton(
                    text = when (option) {
                        SearchSortOption.DATE -> "Date"
                        SearchSortOption.PRICE -> "Price"
                        SearchSortOption.NEARBY -> "Nearby"
                    },
                    selected = uiState.sortOption == option,
                    onClick = { viewModel.setSortOption(option) }
                )
            }
        }

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

        // Results
        if (uiState.isLoading) {
            LoadingView()
        } else if (uiState.results.isEmpty() && uiState.searchQuery.isNotBlank()) {
            EmptyStateView(
                title = "NO RESULTS",
                subtitle = "Try a different search term",
                modifier = Modifier.weight(1f)
            )
        } else if (uiState.results.isEmpty()) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(BurnerDimensions.paddingScreen)
            ) {
                Text(
                    text = "Search for events by name, venue, or genre",
                    style = BurnerTypography.secondary,
                    color = BurnerColors.TextSecondary
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(
                    horizontal = BurnerDimensions.paddingScreen,
                    vertical = BurnerDimensions.spacingSm
                ),
                verticalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm)
            ) {
                items(uiState.results, key = { it.id ?: "" }) { event ->
                    EventCard(
                        event = event,
                        isBookmarked = uiState.bookmarkedEventIds.contains(event.id),
                        onBookmarkClick = { viewModel.toggleBookmark(it) },
                        onClick = { event.id?.let { onEventClick(it) } }
                    )
                }
            }
        }
    }
}
