package com.burner.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun BurnerTopBar(
    title: String,
    modifier: Modifier = Modifier,
    onBackClick: (() -> Unit)? = null,
    onSettingsClick: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {}
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(BurnerDimensions.topBarHeight)
            .padding(horizontal = BurnerDimensions.spacingLg),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Leading action
        if (onBackClick != null) {
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = BurnerColors.White
                )
            }
        } else {
            Spacer(modifier = Modifier.width(48.dp))
        }

        // Title
        Text(
            text = title,
            style = BurnerTypography.sectionHeader,
            color = BurnerColors.White,
            modifier = Modifier.weight(1f),
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        // Trailing actions
        Row(
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.CenterVertically
        ) {
            actions()
            if (onSettingsClick != null) {
                IconButton(onClick = onSettingsClick) {
                    Icon(
                        imageVector = Icons.Filled.Settings,
                        contentDescription = "Settings",
                        tint = BurnerColors.White
                    )
                }
            } else {
                Spacer(modifier = Modifier.width(48.dp))
            }
        }
    }
}

@Composable
fun SheetTopBar(
    title: String,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(BurnerDimensions.spacingLg),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = BurnerTypography.sectionHeader,
            color = BurnerColors.White
        )

        IconButton(onClick = onDismiss) {
            Icon(
                imageVector = Icons.Filled.Close,
                contentDescription = "Close",
                tint = BurnerColors.White
            )
        }
    }
}

@Composable
fun SectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    action: @Composable (() -> Unit)? = null
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = BurnerDimensions.paddingScreen),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = BurnerTypography.label,
            color = BurnerColors.TextSecondary
        )
        action?.invoke()
    }
}

@Composable
fun SettingsRow(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    trailing: @Composable (() -> Unit)? = null
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(
                horizontal = BurnerDimensions.paddingScreen,
                vertical = BurnerDimensions.spacingMd
            ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = BurnerTypography.body,
                color = BurnerColors.White
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = BurnerTypography.secondary,
                    color = BurnerColors.TextSecondary
                )
            }
        }

        if (trailing != null) {
            trailing()
        } else {
            Icon(
                imageVector = Icons.Filled.ChevronRight,
                contentDescription = null,
                tint = BurnerColors.TextSecondary,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

@Composable
fun Divider(
    modifier: Modifier = Modifier,
    color: Color = BurnerColors.Divider
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(BurnerDimensions.dividerHeight)
            .background(color)
    )
}

@Composable
fun LoadingView(
    modifier: Modifier = Modifier,
    message: String = "Loading..."
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(BurnerDimensions.loadingIndicatorSize),
                color = BurnerColors.White,
                strokeWidth = 2.dp
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))
            Text(
                text = message,
                style = BurnerTypography.secondary,
                color = BurnerColors.TextSecondary
            )
        }
    }
}

@Composable
fun EmptyStateView(
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    action: @Composable (() -> Unit)? = null
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(BurnerDimensions.paddingScreen),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = BurnerColors.TextDimmed,
                modifier = Modifier.size(BurnerDimensions.iconXxl)
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))
        }

        Text(
            text = title,
            style = BurnerTypography.sectionHeader,
            color = BurnerColors.White,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))

        Text(
            text = subtitle,
            style = BurnerTypography.secondary,
            color = BurnerColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        if (action != null) {
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))
            action()
        }
    }
}

@Composable
fun GenreChip(
    name: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val backgroundColor = if (selected) BurnerColors.White else BurnerColors.TagBackground
    val contentColor = if (selected) BurnerColors.Black else BurnerColors.White

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(BurnerDimensions.radiusFull))
            .background(backgroundColor)
            .clickable(onClick = onClick)
            .padding(horizontal = BurnerDimensions.spacingLg, vertical = BurnerDimensions.spacingSm),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = name,
            style = BurnerTypography.secondary,
            color = contentColor
        )
    }
}
