package com.burner.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.ConfirmationNumber
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.burner.app.navigation.BottomNavTab
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

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
            .padding(horizontal = BurnerDimensions.spacingLg),
        horizontalArrangement = Arrangement.SpaceAround,
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

    Column(
        modifier = Modifier
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(BurnerDimensions.spacingSm),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = getTabIcon(tab, isSelected),
            contentDescription = tab.label,
            modifier = Modifier.size(BurnerDimensions.iconMd),
            tint = if (isSelected) BurnerColors.White else BurnerColors.TextDimmed
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXs))

        Text(
            text = tab.label,
            style = BurnerTypography.tab,
            color = if (isSelected) BurnerColors.White else BurnerColors.TextDimmed
        )
    }
}

private fun getTabIcon(tab: BottomNavTab, isSelected: Boolean): ImageVector {
    return when (tab) {
        BottomNavTab.EXPLORE -> if (isSelected) Icons.Filled.Explore else Icons.Outlined.Explore
        BottomNavTab.SEARCH -> if (isSelected) Icons.Filled.Search else Icons.Outlined.Search
        BottomNavTab.BOOKMARKS -> if (isSelected) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder
        BottomNavTab.TICKETS -> if (isSelected) Icons.Filled.ConfirmationNumber else Icons.Outlined.ConfirmationNumber
    }
}
