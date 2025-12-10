package com.burner.app.ui.screens.onboarding;

import androidx.compose.animation.*;
import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.graphics.Brush;
import androidx.compose.ui.layout.ContentScale;
import androidx.compose.ui.text.font.FontWeight;
import androidx.compose.ui.text.style.TextAlign;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerTypography;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000N\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0010\"\n\u0000\n\u0002\u0018\u0002\n\u0002\b\r\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0005\u001a$\u0010\u0000\u001a\u00020\u00012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\f\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a:\u0010\u0007\u001a\u00020\u00012\u0006\u0010\b\u001a\u00020\u00042\u0006\u0010\t\u001a\u00020\n2\f\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\u00010\u00062\b\b\u0002\u0010\f\u001a\u00020\r2\b\b\u0002\u0010\u000e\u001a\u00020\nH\u0003\u001a\b\u0010\u000f\u001a\u00020\u0001H\u0003\u001a&\u0010\u0010\u001a\u00020\u00012\u0006\u0010\u0011\u001a\u00020\u00042\u0006\u0010\u0012\u001a\u00020\n2\f\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001aF\u0010\u0013\u001a\u00020\u00012\f\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\f\u0010\u0015\u001a\b\u0012\u0004\u0012\u00020\u00040\u00162\u0012\u0010\u0017\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00010\u00182\f\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a<\u0010\u0019\u001a\u00020\u00012\b\u0010\u001a\u001a\u0004\u0018\u00010\u00042\u0006\u0010\u001b\u001a\u00020\n2\f\u0010\u001c\u001a\b\u0012\u0004\u0012\u00020\u00010\u00062\u0012\u0010\u001d\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00010\u0018H\u0003\u001a\u0010\u0010\u001e\u001a\u00020\u00012\u0006\u0010\u001f\u001a\u00020\u0004H\u0003\u001a\u0016\u0010 \u001a\u00020\u00012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u0003\u001a$\u0010!\u001a\u00020\u00012\f\u0010\"\u001a\b\u0012\u0004\u0012\u00020\u00010\u00062\f\u0010#\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a\u0018\u0010$\u001a\u00020\u00012\u0006\u0010%\u001a\u00020&2\u0006\u0010\'\u001a\u00020(H\u0003\u001a\u0016\u0010)\u001a\u00020\u00012\f\u0010*\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0007\u001a,\u0010+\u001a\u00020\u00012\u0006\u0010,\u001a\u00020-2\f\u0010.\u001a\b\u0012\u0004\u0012\u00020\u00010\u00062\f\u0010#\u001a\b\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a\"\u0010/\u001a\u00020\u00012\u0006\u00100\u001a\u00020\u00042\u0006\u00101\u001a\u00020\u00042\b\b\u0002\u0010\f\u001a\u00020\rH\u0003\u00a8\u00062"}, d2 = {"AuthWelcomeStep", "", "imageUrls", "", "", "onContinue", "Lkotlin/Function0;", "CapsuleButton", "text", "isPrimary", "", "onClick", "modifier", "Landroidx/compose/ui/Modifier;", "enabled", "CompleteStep", "GenrePill", "name", "isSelected", "GenresStep", "genres", "selectedGenres", "", "onGenreToggle", "Lkotlin/Function1;", "LocationStep", "locationName", "isLoading", "onUseCurrentLocation", "onManualEntry", "MosaicCard", "imageUrl", "MosaicRow", "NotificationsStep", "onEnable", "onSkip", "OnboardingAnimatedContent", "uiState", "Lcom/burner/app/ui/screens/onboarding/OnboardingUiState;", "viewModel", "Lcom/burner/app/ui/screens/onboarding/OnboardingViewModel;", "OnboardingFlowScreen", "onComplete", "OnboardingTopBar", "currentStep", "Lcom/burner/app/ui/screens/onboarding/OnboardingStep;", "onBack", "TightHeaderText", "line1", "line2", "app_debug"})
public final class OnboardingFlowScreenKt {
    
    @androidx.compose.runtime.Composable()
    public static final void OnboardingFlowScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onComplete) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.animation.ExperimentalAnimationApi.class})
    @androidx.compose.runtime.Composable()
    private static final void OnboardingAnimatedContent(com.burner.app.ui.screens.onboarding.OnboardingUiState uiState, com.burner.app.ui.screens.onboarding.OnboardingViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void OnboardingTopBar(com.burner.app.ui.screens.onboarding.OnboardingStep currentStep, kotlin.jvm.functions.Function0<kotlin.Unit> onBack, kotlin.jvm.functions.Function0<kotlin.Unit> onSkip) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void AuthWelcomeStep(java.util.List<java.lang.String> imageUrls, kotlin.jvm.functions.Function0<kotlin.Unit> onContinue) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void MosaicRow(java.util.List<java.lang.String> imageUrls) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void MosaicCard(java.lang.String imageUrl) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void TightHeaderText(java.lang.String line1, java.lang.String line2, androidx.compose.ui.Modifier modifier) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void CapsuleButton(java.lang.String text, boolean isPrimary, kotlin.jvm.functions.Function0<kotlin.Unit> onClick, androidx.compose.ui.Modifier modifier, boolean enabled) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void LocationStep(java.lang.String locationName, boolean isLoading, kotlin.jvm.functions.Function0<kotlin.Unit> onUseCurrentLocation, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onManualEntry) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.foundation.layout.ExperimentalLayoutApi.class})
    @androidx.compose.runtime.Composable()
    private static final void GenresStep(java.util.List<java.lang.String> genres, java.util.Set<java.lang.String> selectedGenres, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onGenreToggle, kotlin.jvm.functions.Function0<kotlin.Unit> onContinue) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void GenrePill(java.lang.String name, boolean isSelected, kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void NotificationsStep(kotlin.jvm.functions.Function0<kotlin.Unit> onEnable, kotlin.jvm.functions.Function0<kotlin.Unit> onSkip) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void CompleteStep() {
    }
}