package com.burner.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// Material 3 dark color scheme
private val DarkColorScheme = darkColorScheme(
    primary = BurnerColors.White,
    onPrimary = BurnerColors.Black,
    primaryContainer = BurnerColors.SurfaceVariant,
    onPrimaryContainer = BurnerColors.White,
    secondary = BurnerColors.Secondary,
    onSecondary = BurnerColors.White,
    secondaryContainer = BurnerColors.SurfaceVariant,
    onSecondaryContainer = BurnerColors.White,
    tertiary = BurnerColors.TextTertiary,
    onTertiary = BurnerColors.Black,
    error = BurnerColors.Error,
    onError = BurnerColors.White,
    errorContainer = BurnerColors.Error,
    onErrorContainer = BurnerColors.White,
    background = BurnerColors.Background,
    onBackground = BurnerColors.White,
    surface = BurnerColors.Surface,
    onSurface = BurnerColors.White,
    surfaceVariant = BurnerColors.SurfaceVariant,
    onSurfaceVariant = BurnerColors.TextSecondary,
    outline = BurnerColors.Border,
    outlineVariant = BurnerColors.Divider,
    scrim = BurnerColors.Scrim
)

// Local composition for Burner colors
val LocalBurnerColors = staticCompositionLocalOf { BurnerColorScheme() }

// Local composition for Burner typography
val LocalBurnerTypography = staticCompositionLocalOf { BurnerTypography }

// Local composition for Burner dimensions
val LocalBurnerDimensions = staticCompositionLocalOf { BurnerDimensions }

/**
 * Burner Theme wrapper
 */
@Composable
fun BurnerTheme(
    content: @Composable () -> Unit
) {
    val colorScheme = DarkColorScheme
    val burnerColors = BurnerColorScheme()

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = BurnerColors.Black.toArgb()
            window.navigationBarColor = BurnerColors.Black.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = false
                isAppearanceLightNavigationBars = false
            }
        }
    }

    CompositionLocalProvider(
        LocalBurnerColors provides burnerColors,
        LocalBurnerTypography provides BurnerTypography,
        LocalBurnerDimensions provides BurnerDimensions
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            content = content
        )
    }
}

/**
 * Object to access Burner theme values
 */
object BurnerTheme {
    val colors: BurnerColorScheme
        @Composable
        get() = LocalBurnerColors.current

    val typography: BurnerTypography
        @Composable
        get() = LocalBurnerTypography.current

    val dimensions: BurnerDimensions
        @Composable
        get() = LocalBurnerDimensions.current
}
