package com.burner.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    icon: ImageVector? = null
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .height(BurnerDimensions.buttonHeightLg),
        enabled = enabled && !isLoading,
        shape = RoundedCornerShape(BurnerDimensions.radiusFull),
        colors = ButtonDefaults.buttonColors(
            containerColor = BurnerColors.White,
            contentColor = BurnerColors.Black,
            disabledContainerColor = BurnerColors.White.copy(alpha = 0.5f),
            disabledContentColor = BurnerColors.Black.copy(alpha = 0.5f)
        )
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = BurnerColors.Black,
                strokeWidth = 2.dp
            )
        } else {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (icon != null) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(BurnerDimensions.spacingSm))
                }
                Text(
                    text = text,
                    style = BurnerTypography.button
                )
            }
        }
    }
}

@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    icon: ImageVector? = null
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .height(BurnerDimensions.buttonHeightLg),
        enabled = enabled,
        shape = RoundedCornerShape(BurnerDimensions.radiusFull),
        border = BorderStroke(
            width = BurnerDimensions.borderNormal,
            color = if (enabled) BurnerColors.White else BurnerColors.White.copy(alpha = 0.5f)
        ),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = BurnerColors.White,
            disabledContentColor = BurnerColors.White.copy(alpha = 0.5f)
        )
    ) {
        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(BurnerDimensions.spacingSm))
            }
            Text(
                text = text,
                style = BurnerTypography.button
            )
        }
    }
}

@Composable
fun TextButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    color: Color = BurnerColors.White
) {
    androidx.compose.material3.TextButton(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled
    ) {
        Text(
            text = text,
            style = BurnerTypography.secondary,
            color = if (enabled) color else color.copy(alpha = 0.5f)
        )
    }
}

@Composable
fun IconTextButton(
    text: String,
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .height(BurnerDimensions.buttonHeightMd),
        enabled = enabled,
        shape = RoundedCornerShape(BurnerDimensions.radiusFull),
        border = BorderStroke(
            width = BurnerDimensions.borderNormal,
            color = if (enabled) BurnerColors.White else BurnerColors.White.copy(alpha = 0.5f)
        ),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = BurnerColors.White,
            disabledContentColor = BurnerColors.White.copy(alpha = 0.5f)
        ),
        contentPadding = PaddingValues(horizontal = BurnerDimensions.spacingLg)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.width(BurnerDimensions.spacingSm))
        Text(
            text = text,
            style = BurnerTypography.secondary
        )
    }
}

@Composable
fun ChipButton(
    text: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val backgroundColor = if (selected) BurnerColors.White else Color.Transparent
    val contentColor = if (selected) BurnerColors.Black else BurnerColors.White
    val borderColor = if (selected) BurnerColors.White else BurnerColors.Border

    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .height(36.dp),
        shape = RoundedCornerShape(BurnerDimensions.radiusFull),
        border = BorderStroke(BurnerDimensions.borderNormal, borderColor),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = backgroundColor,
            contentColor = contentColor
        ),
        contentPadding = PaddingValues(horizontal = BurnerDimensions.spacingLg, vertical = 0.dp)
    ) {
        Text(
            text = text,
            style = BurnerTypography.secondary,
            textAlign = TextAlign.Center
        )
    }
}
