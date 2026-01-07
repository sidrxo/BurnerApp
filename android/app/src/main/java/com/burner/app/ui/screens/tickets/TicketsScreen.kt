package com.burner.app.ui.screens.tickets

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource // Import needed for custom SVGs
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.burner.app.R // Import needed for R.drawable
import com.burner.app.data.models.Ticket
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerTypography
import java.text.SimpleDateFormat
import java.util.*

enum class TicketFilter { NEXT_UP, HISTORY }

@Composable
fun TicketsScreen(
    onTicketClick: (String) -> Unit,
    onSignInClick: () -> Unit,
    onSettingsClick: () -> Unit = {},
    viewModel: TicketsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedFilter by remember { mutableStateOf(TicketFilter.NEXT_UP) }

    val ticketsToShow = if (selectedFilter == TicketFilter.NEXT_UP) {
        uiState.upcomingTickets
    } else {
        uiState.pastTickets
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        // Header matching iOS ticketsHeader
        TicketsHeader(
            onSettingsClick = {
                if (uiState.isAuthenticated) {
                    onSettingsClick()
                } else {
                    onSignInClick()
                }
            }
        )

        if (!uiState.isAuthenticated) {
            // Signed out empty state
            SignedOutEmptyState(onSignInClick = onSignInClick)
        } else if (uiState.isLoading && ticketsToShow.isEmpty()) {
            LoadingView(message = "Loading your tickets...")
        } else if (uiState.upcomingTickets.isEmpty() && uiState.pastTickets.isEmpty()) {
            // No tickets empty state
            NoTicketsEmptyState(onExploreClick = { /* Navigate to explore */ })
        } else {
            // Show tab bar only if there are past tickets
            if (uiState.pastTickets.isNotEmpty()) {
                TabBarSection(
                    selectedFilter = selectedFilter,
                    onFilterSelected = { selectedFilter = it }
                )
            }

            // Tickets grid
            if (ticketsToShow.isEmpty()) {
                EmptyFilterState(filter = selectedFilter)
            } else {
                TicketsGrid(
                    tickets = ticketsToShow,
                    onTicketClick = onTicketClick
                )
            }
        }
    }
}

@Composable
private fun TicketsHeader(
    onSettingsClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .padding(top = 14.dp, bottom = 30.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Tickets",
            style = BurnerTypography.pageHeader,
            color = BurnerColors.White,
            modifier = Modifier.padding(bottom = 2.dp)
        )

        IconButton(
            onClick = onSettingsClick,
            modifier = Modifier.size(38.dp)
        ) {
            // UPDATED: Using custom settings.xml drawable
            Icon(
                painter = painterResource(id = R.drawable.settings),
                contentDescription = "Settings",
                tint = BurnerColors.White,
                modifier = Modifier.size(24.dp) // Adjust size if needed to match design
            )
        }
    }
}

@Composable
private fun TabBarSection(
    selectedFilter: TicketFilter,
    onFilterSelected: (TicketFilter) -> Unit
) {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    val tabWidth = (screenWidth - 40.dp) / 2
    val indicatorWidth = if (selectedFilter == TicketFilter.NEXT_UP) 55.dp else 60.dp

    val indicatorOffset by animateDpAsState(
        targetValue = if (selectedFilter == TicketFilter.NEXT_UP) {
            (tabWidth - indicatorWidth) / 2
        } else {
            tabWidth + (tabWidth - indicatorWidth) / 2
        },
        label = "indicator"
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(bottom = 16.dp)
    ) {
        // Tab buttons
        Row(modifier = Modifier.fillMaxWidth()) {
            // Next Up tab
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clickable { onFilterSelected(TicketFilter.NEXT_UP) }
                    .padding(vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "NEXT UP",
                    style = BurnerTypography.secondary.copy(
                        fontWeight = if (selectedFilter == TicketFilter.NEXT_UP) FontWeight.Bold else FontWeight.Medium
                    ),
                    color = if (selectedFilter == TicketFilter.NEXT_UP) BurnerColors.White else BurnerColors.TextSecondary
                )
            }

            // History tab
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clickable { onFilterSelected(TicketFilter.HISTORY) }
                    .padding(vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "HISTORY",
                    style = BurnerTypography.secondary.copy(
                        fontWeight = if (selectedFilter == TicketFilter.HISTORY) FontWeight.Bold else FontWeight.Medium
                    ),
                    color = if (selectedFilter == TicketFilter.HISTORY) BurnerColors.White else BurnerColors.TextSecondary
                )
            }
        }

        // Indicator line
        Box(modifier = Modifier.fillMaxWidth()) {
            // Background line
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Color(0xFF262626))
            )
            // Active indicator
            Box(
                modifier = Modifier
                    .offset(x = indicatorOffset)
                    .width(indicatorWidth)
                    .height(2.dp)
                    .background(BurnerColors.White)
            )
        }
    }
}

@Composable
private fun SignedOutEmptyState(onSignInClick: () -> Unit) {
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
            // User icon placeholder
            Box(
                modifier = Modifier
                    .size(140.dp)
                    .padding(bottom = 30.dp)
            )

            Text(
                text = "WHERE WILL",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White
            )
            Text(
                text = "YOU GO?",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Sign in below to get started.",
                style = BurnerTypography.card,
                color = BurnerColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(20.dp))

            PrimaryButton(
                text = "SIGN UP/IN",
                onClick = onSignInClick,
                modifier = Modifier.width(160.dp)
            )
        }
    }
}

@Composable
private fun NoTicketsEmptyState(onExploreClick: () -> Unit) {
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
            // Ticket icon placeholder
            Box(
                modifier = Modifier
                    .size(140.dp)
                    .padding(bottom = 30.dp)
            )

            Text(
                text = "EMPTY",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White
            )
            Text(
                text = "(FOR NOW?)",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Find something worth remembering.",
                style = BurnerTypography.card,
                color = BurnerColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(20.dp))

            PrimaryButton(
                text = "EXPLORE EVENTS",
                onClick = onExploreClick,
                modifier = Modifier.width(200.dp)
            )
        }
    }
}

@Composable
private fun EmptyFilterState(filter: TicketFilter) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = if (filter == TicketFilter.NEXT_UP) "No upcoming tickets" else "No past tickets",
            style = BurnerTypography.card,
            color = BurnerColors.TextSecondary
        )
    }
}

@Composable
private fun TicketsGrid(
    tickets: List<Ticket>,
    onTicketClick: (String) -> Unit
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(3),
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 0.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        items(tickets) { ticket ->
            TicketGridItem(
                ticket = ticket,
                onClick = { ticket.id?.let { onTicketClick(it) } }
            )
        }
        // Bottom padding item
        item { Spacer(modifier = Modifier.height(100.dp)) }
        item { Spacer(modifier = Modifier.height(100.dp)) }
        item { Spacer(modifier = Modifier.height(100.dp)) }
    }
}

@Composable
private fun TicketGridItem(
    ticket: Ticket,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        // Square image
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(RoundedCornerShape(12.dp))
                .background(BurnerColors.CardBackground)
        ) {
            val imageUrl = ticket.eventImageUrl
            if (!imageUrl.isNullOrEmpty()) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = ticket.eventName,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else {
                // Placeholder
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(BurnerColors.SurfaceVariant),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = ticket.eventName.take(2).uppercase(),
                        style = BurnerTypography.sectionHeader,
                        color = BurnerColors.TextDimmed
                    )
                }
            }
        }

        // Event info below image
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 60.dp)
                .padding(top = 8.dp, start = 4.dp, end = 4.dp)
        ) {
            Text(
                text = ticket.eventName,
                style = BurnerTypography.body,
                color = BurnerColors.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            val startDate = ticket.startDate
            startDate?.let { date ->
                Text(
                    text = formatDate(date),
                    style = BurnerTypography.caption,
                    color = BurnerColors.TextSecondary
                )
            }
        }
    }
}

private fun formatDate(date: Date): String {
    val format = SimpleDateFormat("MMM d", Locale.getDefault())
    return format.format(date)
}