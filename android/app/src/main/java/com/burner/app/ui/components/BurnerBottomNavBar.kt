package com.burner.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.burner.app.R
import com.burner.app.navigation.BottomNavTab
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions

@Composable
fun BurnerBottomNavBar(
    currentRoute: String,
    onTabSelected: (BottomNavTab) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(BurnerDimensions.bottomNavHeight)
            .background(BurnerColors.Background)
            .padding(horizontal = 24.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        BottomNavTab.values().forEach { tab ->
            val isSelected = currentRoute == tab.route
            NavItem(
                tab = tab,
                isSelected = isSelected,
                onClick = { onTabSelected(tab) }
            )
        }
    }
}

@Composable
private fun NavItem(
    tab: BottomNavTab,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }

    // Create the base modifier for size
    var iconModifier = Modifier.size(BurnerDimensions.iconMd)

    // If this is the tickets tab, add a 90-degree clockwise rotation
    if (tab == BottomNavTab.TICKETS) {
        iconModifier = iconModifier.rotate(90f)
    }

    Column(
        modifier = Modifier
            .fillMaxHeight()
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            ),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            painter = painterResource(id = getTabIconResId(tab)),
            contentDescription = tab.label,
            modifier = iconModifier, // Use the conditionally rotated modifier
            tint = if (isSelected) BurnerColors.White else BurnerColors.TextDimmed
        )
    }
}

private fun getTabIconResId(tab: BottomNavTab): Int {
    return when (tab) {
        BottomNavTab.EXPLORE -> R.drawable.explore
        BottomNavTab.SEARCH -> R.drawable.search
        BottomNavTab.BOOKMARKS -> R.drawable.heart
        BottomNavTab.TICKETS -> R.drawable.ticket
    }
}