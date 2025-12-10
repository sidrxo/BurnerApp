package com.burner.app.ui.screens.onboarding;

import android.Manifest;
import androidx.compose.animation.*;
import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.text.style.TextAlign;
import com.google.accompanist.permissions.ExperimentalPermissionsApi;
import com.burner.app.ui.components.*;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000P\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\"\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0002\b\t\n\u0002\u0018\u0002\n\u0002\b\u0003\u001a\b\u0010\u0000\u001a\u00020\u0001H\u0003\u001a9\u0010\u0002\u001a\u00020\u00012\b\b\u0002\u0010\u0003\u001a\u00020\u00042\b\b\u0002\u0010\u0005\u001a\u00020\u00062\b\b\u0002\u0010\u0007\u001a\u00020\b2\u0011\u0010\t\u001a\r\u0012\u0004\u0012\u00020\u00010\n\u00a2\u0006\u0002\b\u000bH\u0003\u001aF\u0010\f\u001a\u00020\u00012\f\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u000f0\u000e2\f\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u000f0\u00112\u0012\u0010\u0012\u001a\u000e\u0012\u0004\u0012\u00020\u000f\u0012\u0004\u0012\u00020\u00010\u00132\f\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00010\nH\u0003\u001aJ\u0010\u0015\u001a\u00020\u00012\b\u0010\u0016\u001a\u0004\u0018\u00010\u000f2\u0006\u0010\u0017\u001a\u00020\u00182\f\u0010\u0019\u001a\b\u0012\u0004\u0012\u00020\u00010\n2\u0012\u0010\u001a\u001a\u000e\u0012\u0004\u0012\u00020\u000f\u0012\u0004\u0012\u00020\u00010\u00132\f\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00010\nH\u0003\u001a$\u0010\u001b\u001a\u00020\u00012\f\u0010\u001c\u001a\b\u0012\u0004\u0012\u00020\u00010\n2\f\u0010\u001d\u001a\b\u0012\u0004\u0012\u00020\u00010\nH\u0003\u001a.\u0010\u001e\u001a\u00020\u00012\f\u0010\u001f\u001a\b\u0012\u0004\u0012\u00020\u00010\n2\f\u0010 \u001a\b\u0012\u0004\u0012\u00020\u00010\n2\b\b\u0002\u0010!\u001a\u00020\"H\u0007\u001a$\u0010#\u001a\u00020\u00012\f\u0010 \u001a\b\u0012\u0004\u0012\u00020\u00010\n2\f\u0010$\u001a\b\u0012\u0004\u0012\u00020\u00010\nH\u0003\u00a8\u0006%"}, d2 = {"CompleteStep", "", "FlowRow", "modifier", "Landroidx/compose/ui/Modifier;", "horizontalArrangement", "Landroidx/compose/foundation/layout/Arrangement$Horizontal;", "verticalArrangement", "Landroidx/compose/foundation/layout/Arrangement$Vertical;", "content", "Lkotlin/Function0;", "Landroidx/compose/runtime/Composable;", "GenresStep", "genres", "", "", "selectedGenres", "", "onGenreToggle", "Lkotlin/Function1;", "onContinue", "LocationStep", "locationName", "isLoading", "", "onUseCurrentLocation", "onManualEntry", "NotificationsStep", "onEnable", "onSkip", "OnboardingFlowScreen", "onComplete", "onSignIn", "viewModel", "Lcom/burner/app/ui/screens/onboarding/OnboardingViewModel;", "WelcomeStep", "onExplore", "app_debug"})
public final class OnboardingFlowScreenKt {
    
    @kotlin.OptIn(markerClass = {com.google.accompanist.permissions.ExperimentalPermissionsApi.class})
    @androidx.compose.runtime.Composable()
    public static final void OnboardingFlowScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onComplete, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onSignIn, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.onboarding.OnboardingViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void WelcomeStep(kotlin.jvm.functions.Function0<kotlin.Unit> onSignIn, kotlin.jvm.functions.Function0<kotlin.Unit> onExplore) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void LocationStep(java.lang.String locationName, boolean isLoading, kotlin.jvm.functions.Function0<kotlin.Unit> onUseCurrentLocation, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onManualEntry, kotlin.jvm.functions.Function0<kotlin.Unit> onContinue) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void GenresStep(java.util.List<java.lang.String> genres, java.util.Set<java.lang.String> selectedGenres, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onGenreToggle, kotlin.jvm.functions.Function0<kotlin.Unit> onContinue) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void FlowRow(androidx.compose.ui.Modifier modifier, androidx.compose.foundation.layout.Arrangement.Horizontal horizontalArrangement, androidx.compose.foundation.layout.Arrangement.Vertical verticalArrangement, kotlin.jvm.functions.Function0<kotlin.Unit> content) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void NotificationsStep(kotlin.jvm.functions.Function0<kotlin.Unit> onEnable, kotlin.jvm.functions.Function0<kotlin.Unit> onSkip) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void CompleteStep() {
    }
}