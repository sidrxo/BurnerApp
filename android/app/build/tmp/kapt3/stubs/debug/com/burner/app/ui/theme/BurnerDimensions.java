package com.burner.app.ui.theme;

import androidx.compose.ui.unit.Dp;

/**
 * Burner App Dimensions
 * Consistent spacing and sizing throughout the app
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\\\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u0019\u0010\u0003\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u0005\u0010\u0006R\u0019\u0010\b\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\t\u0010\u0006R\u0019\u0010\n\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u000b\u0010\u0006R\u0019\u0010\f\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\r\u0010\u0006R\u0019\u0010\u000e\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u000f\u0010\u0006R\u0019\u0010\u0010\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u0011\u0010\u0006R\u0019\u0010\u0012\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u0013\u0010\u0006R\u0019\u0010\u0014\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u0015\u0010\u0006R\u0019\u0010\u0016\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u0017\u0010\u0006R\u0019\u0010\u0018\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u0019\u0010\u0006R\u0019\u0010\u001a\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u001b\u0010\u0006R\u0019\u0010\u001c\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u001d\u0010\u0006R\u0019\u0010\u001e\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\u001f\u0010\u0006R\u0019\u0010 \u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b!\u0010\u0006R\u0019\u0010\"\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b#\u0010\u0006R\u0019\u0010$\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b%\u0010\u0006R\u0019\u0010&\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b\'\u0010\u0006R\u0019\u0010(\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b)\u0010\u0006R\u0019\u0010*\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b+\u0010\u0006R\u0019\u0010,\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b-\u0010\u0006R\u0019\u0010.\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b/\u0010\u0006R\u0019\u00100\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b1\u0010\u0006R\u0019\u00102\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b3\u0010\u0006R\u0019\u00104\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b5\u0010\u0006R\u0019\u00106\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b7\u0010\u0006R\u0019\u00108\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b9\u0010\u0006R\u0019\u0010:\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b;\u0010\u0006R\u0019\u0010<\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b=\u0010\u0006R\u0019\u0010>\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b?\u0010\u0006R\u0019\u0010@\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bA\u0010\u0006R\u0019\u0010B\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bC\u0010\u0006R\u0019\u0010D\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bE\u0010\u0006R\u0019\u0010F\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bG\u0010\u0006R\u0019\u0010H\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bI\u0010\u0006R\u0019\u0010J\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bK\u0010\u0006R\u0019\u0010L\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bM\u0010\u0006R\u0019\u0010N\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bO\u0010\u0006R\u0019\u0010P\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bQ\u0010\u0006R\u0019\u0010R\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bS\u0010\u0006R\u0019\u0010T\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bU\u0010\u0006R\u0019\u0010V\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bW\u0010\u0006R\u0019\u0010X\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\bY\u0010\u0006R\u0019\u0010Z\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b[\u0010\u0006R\u0019\u0010\\\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b]\u0010\u0006R\u0019\u0010^\u001a\u00020\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\n\n\u0002\u0010\u0007\u001a\u0004\b_\u0010\u0006\u0082\u0002\u000b\n\u0005\b\u00a1\u001e0\u0001\n\u0002\b!\u00a8\u0006`"}, d2 = {"Lcom/burner/app/ui/theme/BurnerDimensions;", "", "()V", "borderNormal", "Landroidx/compose/ui/unit/Dp;", "getBorderNormal-D9Ej5fM", "()F", "F", "borderThick", "getBorderThick-D9Ej5fM", "borderThin", "getBorderThin-D9Ej5fM", "bottomNavHeight", "getBottomNavHeight-D9Ej5fM", "buttonHeightLg", "getButtonHeightLg-D9Ej5fM", "buttonHeightMd", "getButtonHeightMd-D9Ej5fM", "buttonHeightSm", "getButtonHeightSm-D9Ej5fM", "cardHeightFeatured", "getCardHeightFeatured-D9Ej5fM", "cardHeightLg", "getCardHeightLg-D9Ej5fM", "cardHeightMd", "getCardHeightMd-D9Ej5fM", "cardHeightSm", "getCardHeightSm-D9Ej5fM", "cardHeightXl", "getCardHeightXl-D9Ej5fM", "dividerHeight", "getDividerHeight-D9Ej5fM", "iconLg", "getIconLg-D9Ej5fM", "iconMd", "getIconMd-D9Ej5fM", "iconSm", "getIconSm-D9Ej5fM", "iconXl", "getIconXl-D9Ej5fM", "iconXs", "getIconXs-D9Ej5fM", "iconXxl", "getIconXxl-D9Ej5fM", "imageLg", "getImageLg-D9Ej5fM", "imageMd", "getImageMd-D9Ej5fM", "imageSm", "getImageSm-D9Ej5fM", "imageThumb", "getImageThumb-D9Ej5fM", "loadingIndicatorSize", "getLoadingIndicatorSize-D9Ej5fM", "paddingButton", "getPaddingButton-D9Ej5fM", "paddingCard", "getPaddingCard-D9Ej5fM", "paddingScreen", "getPaddingScreen-D9Ej5fM", "qrCodeSize", "getQrCodeSize-D9Ej5fM", "radiusFull", "getRadiusFull-D9Ej5fM", "radiusLg", "getRadiusLg-D9Ej5fM", "radiusMd", "getRadiusMd-D9Ej5fM", "radiusSm", "getRadiusSm-D9Ej5fM", "radiusXl", "getRadiusXl-D9Ej5fM", "radiusXs", "getRadiusXs-D9Ej5fM", "radiusXxl", "getRadiusXxl-D9Ej5fM", "spacingHuge", "getSpacingHuge-D9Ej5fM", "spacingLg", "getSpacingLg-D9Ej5fM", "spacingMd", "getSpacingMd-D9Ej5fM", "spacingSm", "getSpacingSm-D9Ej5fM", "spacingXl", "getSpacingXl-D9Ej5fM", "spacingXs", "getSpacingXs-D9Ej5fM", "spacingXxl", "getSpacingXxl-D9Ej5fM", "spacingXxs", "getSpacingXxs-D9Ej5fM", "spacingXxxl", "getSpacingXxxl-D9Ej5fM", "topBarHeight", "getTopBarHeight-D9Ej5fM", "app_debug"})
public final class BurnerDimensions {
    private static final float spacingXxs = 0.0F;
    private static final float spacingXs = 0.0F;
    private static final float spacingSm = 0.0F;
    private static final float spacingMd = 0.0F;
    private static final float spacingLg = 0.0F;
    private static final float spacingXl = 0.0F;
    private static final float spacingXxl = 0.0F;
    private static final float spacingXxxl = 0.0F;
    private static final float spacingHuge = 0.0F;
    private static final float paddingScreen = 0.0F;
    private static final float paddingCard = 0.0F;
    private static final float paddingButton = 0.0F;
    private static final float radiusXs = 0.0F;
    private static final float radiusSm = 0.0F;
    private static final float radiusMd = 0.0F;
    private static final float radiusLg = 0.0F;
    private static final float radiusXl = 0.0F;
    private static final float radiusXxl = 0.0F;
    private static final float radiusFull = 0.0F;
    private static final float borderThin = 0.0F;
    private static final float borderNormal = 0.0F;
    private static final float borderThick = 0.0F;
    private static final float iconXs = 0.0F;
    private static final float iconSm = 0.0F;
    private static final float iconMd = 0.0F;
    private static final float iconLg = 0.0F;
    private static final float iconXl = 0.0F;
    private static final float iconXxl = 0.0F;
    private static final float buttonHeightSm = 0.0F;
    private static final float buttonHeightMd = 0.0F;
    private static final float buttonHeightLg = 0.0F;
    private static final float cardHeightSm = 0.0F;
    private static final float cardHeightMd = 0.0F;
    private static final float cardHeightLg = 0.0F;
    private static final float cardHeightXl = 0.0F;
    private static final float cardHeightFeatured = 0.0F;
    private static final float imageThumb = 0.0F;
    private static final float imageSm = 0.0F;
    private static final float imageMd = 0.0F;
    private static final float imageLg = 0.0F;
    private static final float bottomNavHeight = 0.0F;
    private static final float topBarHeight = 0.0F;
    private static final float dividerHeight = 0.0F;
    private static final float qrCodeSize = 0.0F;
    private static final float loadingIndicatorSize = 0.0F;
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.ui.theme.BurnerDimensions INSTANCE = null;
    
    private BurnerDimensions() {
        super();
    }
}