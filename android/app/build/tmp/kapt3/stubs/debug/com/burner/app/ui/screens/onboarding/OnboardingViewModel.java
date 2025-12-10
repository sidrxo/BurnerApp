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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000N\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0005\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B!\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0001\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\b\u0010\u0012\u001a\u00020\u0013H\u0007J\b\u0010\u0014\u001a\u00020\u0013H\u0002J\u0006\u0010\u0015\u001a\u00020\u0013J\b\u0010\u0016\u001a\u00020\u0013H\u0002J\u000e\u0010\u0017\u001a\u00020\u00132\u0006\u0010\u0018\u001a\u00020\u0019J\u000e\u0010\u001a\u001a\u00020\u00132\u0006\u0010\u001b\u001a\u00020\u001cJ\u000e\u0010\u001d\u001a\u00020\u00132\u0006\u0010\u001e\u001a\u00020\u0019R\u0014\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\f\u001a\u00020\rX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\u000b0\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011\u00a8\u0006\u001f"}, d2 = {"Lcom/burner/app/ui/screens/onboarding/OnboardingViewModel;", "Landroidx/lifecycle/ViewModel;", "preferencesRepository", "Lcom/burner/app/data/repository/PreferencesRepository;", "tagRepository", "Lcom/burner/app/data/repository/TagRepository;", "context", "Landroid/content/Context;", "(Lcom/burner/app/data/repository/PreferencesRepository;Lcom/burner/app/data/repository/TagRepository;Landroid/content/Context;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/onboarding/OnboardingUiState;", "fusedLocationClient", "Lcom/google/android/gms/location/FusedLocationProviderClient;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "detectCurrentLocation", "", "loadGenres", "nextStep", "savePreferences", "setLocationManually", "cityName", "", "setNotificationsEnabled", "enabled", "", "toggleGenre", "genre", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class OnboardingViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.PreferencesRepository preferencesRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.TagRepository tagRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final android.content.Context context = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.onboarding.OnboardingUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.onboarding.OnboardingUiState> uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final com.google.android.gms.location.FusedLocationProviderClient fusedLocationClient = null;
    
    @javax.inject.Inject()
    public OnboardingViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.PreferencesRepository preferencesRepository, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.TagRepository tagRepository, @dagger.hilt.android.qualifiers.ApplicationContext()
    @org.jetbrains.annotations.NotNull()
    android.content.Context context) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.onboarding.OnboardingUiState> getUiState() {
        return null;
    }
    
    private final void loadGenres() {
    }
    
    public final void nextStep() {
    }
    
    @android.annotation.SuppressLint(value = {"MissingPermission"})
    public final void detectCurrentLocation() {
    }
    
    public final void setLocationManually(@org.jetbrains.annotations.NotNull()
    java.lang.String cityName) {
    }
    
    public final void toggleGenre(@org.jetbrains.annotations.NotNull()
    java.lang.String genre) {
    }
    
    public final void setNotificationsEnabled(boolean enabled) {
    }
    
    private final void savePreferences() {
    }
}