package com.burner.app.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Burner App Color Palette
 * Matching iOS dark theme
 */
object BurnerColors {
    // Primary colors
    val Black = Color(0xFF000000)
    val White = Color(0xFFFFFFFF)

    // Background colors
    val Background = Black
    val Surface = Color(0xFF0D0D0D)
    val SurfaceVariant = Color(0xFF1A1A1A)
    val CardBackground = Color(0x0DFFFFFF) // white.opacity(0.05)

    // Text colors
    val TextPrimary = White
    val TextSecondary = Color(0xFFB3B3B3) // gray
    val TextTertiary = Color(0xB3FFFFFF) // white.opacity(0.7)
    val TextDimmed = Color(0x80FFFFFF) // white.opacity(0.5)

    // Accent colors
    val Primary = White
    val PrimaryVariant = Color(0xFFE0E0E0)
    val Secondary = Color(0xFF808080)

    // Status colors
    val Success = Color(0xFF4CAF50) // Green
    val Error = Color(0xFFE53935) // Red
    val Warning = Color(0xFFFF9800) // Orange
    val Info = Color(0xFF2196F3) // Blue

    // Specific UI colors
    val Divider = Color(0x1AFFFFFF) // white.opacity(0.1)
    val Border = Color(0x33FFFFFF) // white.opacity(0.2)
    val Overlay = Color(0x80000000) // black.opacity(0.5)
    val Scrim = Color(0xCC000000) // black.opacity(0.8)

    // Gradient colors
    val GradientStart = Color(0x00000000)
    val GradientEnd = Color(0xCC000000)

    // Tag/Genre colors
    val TagBackground = Color(0x1AFFFFFF)
    val TagSelectedBackground = White
    val TagSelectedText = Black
}

/**
 * Color scheme for the app
 */
data class BurnerColorScheme(
    val background: Color = BurnerColors.Background,
    val surface: Color = BurnerColors.Surface,
    val surfaceVariant: Color = BurnerColors.SurfaceVariant,
    val cardBackground: Color = BurnerColors.CardBackground,
    val primary: Color = BurnerColors.Primary,
    val primaryVariant: Color = BurnerColors.PrimaryVariant,
    val secondary: Color = BurnerColors.Secondary,
    val textPrimary: Color = BurnerColors.TextPrimary,
    val textSecondary: Color = BurnerColors.TextSecondary,
    val textTertiary: Color = BurnerColors.TextTertiary,
    val textDimmed: Color = BurnerColors.TextDimmed,
    val success: Color = BurnerColors.Success,
    val error: Color = BurnerColors.Error,
    val warning: Color = BurnerColors.Warning,
    val info: Color = BurnerColors.Info,
    val divider: Color = BurnerColors.Divider,
    val border: Color = BurnerColors.Border,
    val overlay: Color = BurnerColors.Overlay,
    val scrim: Color = BurnerColors.Scrim
)
