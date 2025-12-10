package com.burner.app.ui.screens.onboarding;

import android.annotation.SuppressLint;
import android.content.Context;
import android.location.Geocoder;
import androidx.lifecycle.ViewModel;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationServices;
import com.burner.app.data.models.Tag;
import com.burner.app.data.repository.PreferencesRepository;
import com.burner.app.data.repository.TagRepository;
import dagger.hilt.android.lifecycle.HiltViewModel;
import dagger.hilt.android.qualifiers.ApplicationContext;
import kotlinx.coroutines.flow.StateFlow;
import java.util.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000:\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0006\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010 \n\u0000\n\u0002\u0010\"\n\u0002\b\u001d\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001Bg\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u0012\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u0007\u0012\b\b\u0002\u0010\t\u001a\u00020\n\u0012\u000e\b\u0002\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\u00050\f\u0012\u000e\b\u0002\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u00050\u000e\u0012\b\b\u0002\u0010\u000f\u001a\u00020\n\u00a2\u0006\u0002\u0010\u0010J\t\u0010\u001f\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010 \u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u0010\u0010!\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0017J\u0010\u0010\"\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0017J\t\u0010#\u001a\u00020\nH\u00c6\u0003J\u000f\u0010$\u001a\b\u0012\u0004\u0012\u00020\u00050\fH\u00c6\u0003J\u000f\u0010%\u001a\b\u0012\u0004\u0012\u00020\u00050\u000eH\u00c6\u0003J\t\u0010&\u001a\u00020\nH\u00c6\u0003Jp\u0010\'\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u00052\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00072\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u00072\b\b\u0002\u0010\t\u001a\u00020\n2\u000e\b\u0002\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\u00050\f2\u000e\b\u0002\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u00050\u000e2\b\b\u0002\u0010\u000f\u001a\u00020\nH\u00c6\u0001\u00a2\u0006\u0002\u0010(J\u0013\u0010)\u001a\u00020\n2\b\u0010*\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010+\u001a\u00020,H\u00d6\u0001J\t\u0010-\u001a\u00020\u0005H\u00d6\u0001R\u0017\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\u00050\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014R\u0011\u0010\t\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\u0015R\u0015\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\n\n\u0002\u0010\u0018\u001a\u0004\b\u0016\u0010\u0017R\u0015\u0010\b\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\n\n\u0002\u0010\u0018\u001a\u0004\b\u0019\u0010\u0017R\u0013\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u001bR\u0011\u0010\u000f\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u0015R\u0017\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u00050\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u001e\u00a8\u0006."}, d2 = {"Lcom/burner/app/ui/screens/onboarding/OnboardingUiState;", "", "currentStep", "Lcom/burner/app/ui/screens/onboarding/OnboardingStep;", "locationName", "", "locationLat", "", "locationLon", "isLoadingLocation", "", "availableGenres", "", "selectedGenres", "", "notificationsEnabled", "(Lcom/burner/app/ui/screens/onboarding/OnboardingStep;Ljava/lang/String;Ljava/lang/Double;Ljava/lang/Double;ZLjava/util/List;Ljava/util/Set;Z)V", "getAvailableGenres", "()Ljava/util/List;", "getCurrentStep", "()Lcom/burner/app/ui/screens/onboarding/OnboardingStep;", "()Z", "getLocationLat", "()Ljava/lang/Double;", "Ljava/lang/Double;", "getLocationLon", "getLocationName", "()Ljava/lang/String;", "getNotificationsEnabled", "getSelectedGenres", "()Ljava/util/Set;", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "copy", "(Lcom/burner/app/ui/screens/onboarding/OnboardingStep;Ljava/lang/String;Ljava/lang/Double;Ljava/lang/Double;ZLjava/util/List;Ljava/util/Set;Z)Lcom/burner/app/ui/screens/onboarding/OnboardingUiState;", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class OnboardingUiState {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.ui.screens.onboarding.OnboardingStep currentStep = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String locationName = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double locationLat = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double locationLon = null;
    private final boolean isLoadingLocation = false;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<java.lang.String> availableGenres = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.Set<java.lang.String> selectedGenres = null;
    private final boolean notificationsEnabled = false;
    
    public OnboardingUiState(@org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.onboarding.OnboardingStep currentStep, @org.jetbrains.annotations.Nullable()
    java.lang.String locationName, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLon, boolean isLoadingLocation, @org.jetbrains.annotations.NotNull()
    java.util.List<java.lang.String> availableGenres, @org.jetbrains.annotations.NotNull()
    java.util.Set<java.lang.String> selectedGenres, boolean notificationsEnabled) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.onboarding.OnboardingStep getCurrentStep() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getLocationName() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double getLocationLat() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double getLocationLon() {
        return null;
    }
    
    public final boolean isLoadingLocation() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<java.lang.String> getAvailableGenres() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.Set<java.lang.String> getSelectedGenres() {
        return null;
    }
    
    public final boolean getNotificationsEnabled() {
        return false;
    }
    
    public OnboardingUiState() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.onboarding.OnboardingStep component1() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double component4() {
        return null;
    }
    
    public final boolean component5() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<java.lang.String> component6() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.Set<java.lang.String> component7() {
        return null;
    }
    
    public final boolean component8() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.onboarding.OnboardingUiState copy(@org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.onboarding.OnboardingStep currentStep, @org.jetbrains.annotations.Nullable()
    java.lang.String locationName, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLon, boolean isLoadingLocation, @org.jetbrains.annotations.NotNull()
    java.util.List<java.lang.String> availableGenres, @org.jetbrains.annotations.NotNull()
    java.util.Set<java.lang.String> selectedGenres, boolean notificationsEnabled) {
        return null;
    }
    
    @java.lang.Override()
    public boolean equals(@org.jetbrains.annotations.Nullable()
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override()
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override()
    @org.jetbrains.annotations.NotNull()
    public java.lang.String toString() {
        return null;
    }
}