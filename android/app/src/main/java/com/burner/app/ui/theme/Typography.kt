package com.burner.app.ui.theme

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.burner.app.R

/**
 * Burner App Typography
 * Matching iOS Helvetica-based typography
 * Using system default (Roboto) which is Android's equivalent
 */

// Font family - using default system font (Roboto) as Android equivalent of Helvetica
val BurnerFontFamily = FontFamily.Default

/**
 * Typography styles matching iOS FontExtensions
 */
object BurnerTypography {

    // Caption - 12sp (iOS: appCaption)
    val caption = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.sp
    )

    // Secondary - 14sp (iOS: appSecondary)
    val secondary = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.sp
    )

    // Body - 16sp (iOS: appBody with -0.3 kerning)
    val body = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = (-0.3).sp
    )

    // Card - 18sp (iOS: appCard)
    val card = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 18.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.sp
    )

    // Section Header - 24sp (iOS: appSectionHeader with regular weight)
    val sectionHeader = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp,
        lineHeight = 28.sp,
        letterSpacing = (-0.5).sp
    )

    // Page Header - 28sp (iOS: appPageHeader with regular weight and -1.5 kerning)
    val pageHeader = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 28.sp,
        lineHeight = 32.sp,
        letterSpacing = (-1.5).sp
    )

    // Hero - 32sp (iOS: appHero with tight letter spacing)
    val hero = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        lineHeight = 36.sp,
        letterSpacing = (-1.5).sp
    )

    // Button - 16sp monospaced (iOS: appButton with appMonospaced)
    val button = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 1.sp
    )

    // Label - 12sp, all caps
    val label = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 1.sp
    )

    // Price - 20sp bold
    val price = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 20.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.sp
    )

    // Tab - 10sp for bottom navigation
    val tab = TextStyle(
        fontFamily = BurnerFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 10.sp,
        lineHeight = 14.sp,
        letterSpacing = 0.sp
    )
}

/**
 * Extension to get semibold variant
 */
fun TextStyle.semiBold(): TextStyle = this.copy(fontWeight = FontWeight.SemiBold)

/**
 * Extension to get bold variant
 */
fun TextStyle.bold(): TextStyle = this.copy(fontWeight = FontWeight.Bold)

/**
 * Extension to get regular variant
 */
fun TextStyle.regular(): TextStyle = this.copy(fontWeight = FontWeight.Normal)
