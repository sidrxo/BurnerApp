package com.burner.app.ui.screens.search

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.data.repository.SearchSortOption
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
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
            .pointerInput(Unit) {
                detectTapGestures { focusManager.clearFocus() }
            }
    ) {
        // Header matching iOS
        SearchHeader()

        // Search field
        SearchFieldSection(
            value = uiState.searchQuery,
            onValueChange = viewModel::updateSearchQuery,
            onSearch = {
                focusManager.clearFocus()
                viewModel.search()
            },
            onClear = {
                viewModel.updateSearchQuery("")
            },
            isSearching = uiState.isLoading,
            focusRequester = focusRequester
        )

        // Filter buttons
        FilterSection(
            selectedOption = uiState.sortOption,
            onOptionSelected = { viewModel.setSortOption(it) }
        )

        // Results
        ContentSection(
            uiState = uiState,
            onEventClick = onEventClick,
            onBookmarkClick = { viewModel.toggleBookmark(it) }
        )
    }
}

@Composable
private fun SearchHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .padding(top = 14.dp, bottom = 30.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Search",
            style = BurnerTypography.pageHeader,
            color = BurnerColors.White,
            modifier = Modifier.padding(bottom = 2.dp)
        )

        // Empty spacer for symmetry (matching iOS)
        Box(modifier = Modifier.size(38.dp))
    }
}

@Composable
private fun SearchFieldSection(
    value: String,
    onValueChange: (String) -> Unit,
    onSearch: () -> Unit,
    onClear: () -> Unit,
    isSearching: Boolean,
    focusRequester: FocusRequester
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .height(52.dp)
            .background(
                color = Color(0xFF161617),
                shape = RoundedCornerShape(25.dp)
            )
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Search icon or loading indicator
        Box(
            modifier = Modifier.size(24.dp),
            contentAlignment = Alignment.Center
        ) {
            if (isSearching && value.isNotEmpty()) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    color = BurnerColors.TextSecondary,
                    strokeWidth = 2.dp
                )
            } else {
                Icon(
                    imageVector = Icons.Filled.Search,
                    contentDescription = "Search",
                    tint = BurnerColors.TextSecondary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Text field
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier
                .weight(1f)
                .focusRequester(focusRequester),
            textStyle = BurnerTypography.body.copy(color = BurnerColors.White),
            singleLine = true,
            cursorBrush = SolidColor(BurnerColors.White),
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
            keyboardActions = KeyboardActions(onSearch = { onSearch() }),
            decorationBox = { innerTextField ->
                Box {
                    if (value.isEmpty()) {
                        Text(
                            text = "Search events",
                            style = BurnerTypography.body,
                            color = BurnerColors.TextSecondary
                        )
                    }
                    innerTextField()
                }
            }
        )

        // Clear button
        if (value.isNotEmpty()) {
            IconButton(
                onClick = onClear,
                modifier = Modifier.size(24.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Clear,
                    contentDescription = "Clear",
                    tint = BurnerColors.TextSecondary,
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

@Composable
private fun FilterSection(
    selectedOption: SearchSortOption,
    onOptionSelected: (SearchSortOption) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 16.dp, bottom = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        FilterButton(
            text = "DATE",
            isSelected = selectedOption == SearchSortOption.DATE,
            onClick = { onOptionSelected(SearchSortOption.DATE) }
        )
        FilterButton(
            text = "PRICE",
            isSelected = selectedOption == SearchSortOption.PRICE,
            onClick = { onOptionSelected(SearchSortOption.PRICE) }
        )
        FilterButton(
            text = "NEARBY",
            isSelected = selectedOption == SearchSortOption.NEARBY,
            onClick = { onOptionSelected(SearchSortOption.NEARBY) }
        )
        Spacer(modifier = Modifier.weight(1f))
    }
}

@Composable
private fun FilterButton(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor = if (isSelected) BurnerColors.White else Color.Transparent
    val textColor = if (isSelected) BurnerColors.Black else BurnerColors.White
    val borderColor = if (isSelected) BurnerColors.White else BurnerColors.Border

    Surface(
        onClick = onClick,
        modifier = Modifier.height(32.dp),
        shape = RoundedCornerShape(16.dp),
        color = backgroundColor,
        border = androidx.compose.foundation.BorderStroke(1.dp, borderColor)
    ) {
        Box(
            modifier = Modifier.padding(horizontal = 16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                style = BurnerTypography.caption.copy(
                    letterSpacing = 0.5.sp
                ),
                color = textColor
            )
        }
    }
}

@Composable
private fun ContentSection(
    uiState: SearchUiState,
    onEventClick: (String) -> Unit,
    onBookmarkClick: (com.burner.app.data.models.Event) -> Unit
) {
    when {
        uiState.isLoading && uiState.results.isEmpty() -> {
            LoadingStateView()
        }
        uiState.results.isEmpty() && uiState.searchQuery.isNotBlank() -> {
            EmptySearchView()
        }
        uiState.results.isEmpty() -> {
            // Default state - show all events initially sorted by filter
        }
        else -> {
            ResultsList(
                events = uiState.results,
                bookmarkedIds = uiState.bookmarkedEventIds,
                onEventClick = onEventClick,
                onBookmarkClick = onBookmarkClick
            )
        }
    }
}

@Composable
private fun LoadingStateView() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(50.dp),
            color = BurnerColors.White,
            strokeWidth = 2.dp
        )
    }
}

@Composable
private fun EmptySearchView() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .padding(top = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Filled.Search,
            contentDescription = null,
            tint = BurnerColors.TextDimmed.copy(alpha = 0.5f),
            modifier = Modifier.size(48.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "No events found",
            style = BurnerTypography.card,
            color = BurnerColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Try adjusting your search",
            style = BurnerTypography.secondary,
            color = BurnerColors.TextDimmed
        )
    }
}

@Composable
private fun ResultsList(
    events: List<com.burner.app.data.models.Event>,
    bookmarkedIds: Set<String>,
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
                isBookmarked = bookmarkedIds.contains(event.id),
                onBookmarkClick = onBookmarkClick,
                onClick = { event.id?.let { onEventClick(it) } }
            )
        }
    }
}
