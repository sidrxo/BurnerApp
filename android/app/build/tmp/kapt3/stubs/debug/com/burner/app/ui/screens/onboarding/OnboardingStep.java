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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0007\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005j\u0002\b\u0006j\u0002\b\u0007\u00a8\u0006\b"}, d2 = {"Lcom/burner/app/ui/screens/onboarding/OnboardingStep;", "", "(Ljava/lang/String;I)V", "WELCOME", "LOCATION", "GENRES", "NOTIFICATIONS", "COMPLETE", "app_debug"})
public enum OnboardingStep {
    /*public static final*/ WELCOME /* = new WELCOME() */,
    /*public static final*/ LOCATION /* = new LOCATION() */,
    /*public static final*/ GENRES /* = new GENRES() */,
    /*public static final*/ NOTIFICATIONS /* = new NOTIFICATIONS() */,
    /*public static final*/ COMPLETE /* = new COMPLETE() */;
    
    OnboardingStep() {
    }
    
    @org.jetbrains.annotations.NotNull()
    public static kotlin.enums.EnumEntries<com.burner.app.ui.screens.onboarding.OnboardingStep> getEntries() {
        return null;
    }
}