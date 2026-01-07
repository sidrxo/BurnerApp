package com.burner.app.ui.screens.main

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import com.burner.app.navigation.BottomNavTab
import com.burner.app.ui.components.BurnerBottomNavBar
import com.burner.app.ui.screens.bookmarks.BookmarksScreen
import com.burner.app.ui.screens.explore.ExploreScreen
import com.burner.app.ui.screens.search.SearchScreen
import com.burner.app.ui.screens.tickets.TicketsScreen
import com.burner.app.ui.theme.BurnerColors
import kotlinx.coroutines.launch

@OptIn(ExperimentalFoundationApi::class) // FIX 1: Add OptIn for Experimental API
@Composable
fun MainTabsScreen(
    onEventClick: (String) -> Unit,
    onSignInClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    // 4 Tabs: Explore, Search, Bookmarks, Tickets
    // The lambda { 4 } defines the page count
    val pagerState = rememberPagerState(pageCount = { 4 })
    val coroutineScope = rememberCoroutineScope()

    // Map the current page index to a Route String for the BottomBar highlighter
    val currentRoute = when (pagerState.currentPage) {
        0 -> BottomNavTab.EXPLORE.route
        1 -> BottomNavTab.SEARCH.route
        2 -> BottomNavTab.BOOKMARKS.route
        3 -> BottomNavTab.TICKETS.route
        else -> BottomNavTab.EXPLORE.route
    }

    Scaffold(
        containerColor = BurnerColors.Background,
        bottomBar = {
            BurnerBottomNavBar(
                currentRoute = currentRoute,
                onTabSelected = { tab ->
                    // Scroll to the specific page when a tab is clicked
                    val page = when (tab) {
                        BottomNavTab.EXPLORE -> 0
                        BottomNavTab.SEARCH -> 1
                        BottomNavTab.BOOKMARKS -> 2
                        BottomNavTab.TICKETS -> 3
                    }
                    coroutineScope.launch {
                        pagerState.animateScrollToPage(page)
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.fillMaxSize(),
                // FIX 2: Renamed from 'beyondViewportPageCount' to 'beyondBoundsPageCount'
                beyondBoundsPageCount = 3
            ) { page ->
                // The content inside here is a Composable scope
                when (page) {
                    0 -> ExploreScreen(
                        onEventClick = onEventClick
                    )
                    1 -> SearchScreen(
                        onEventClick = onEventClick
                    )
                    2 -> BookmarksScreen(
                        onEventClick = onEventClick,
                        onExploreClick = {
                            coroutineScope.launch { pagerState.animateScrollToPage(0) }
                        },
                        onSignInClick = onSignInClick
                    )
                    3 -> TicketsScreen(
                        onTicketClick = { /* Navigate to detail if needed */ },
                        onSignInClick = onSignInClick,
                        onSettingsClick = onSettingsClick
                    )
                }
            }
        }
    }
}