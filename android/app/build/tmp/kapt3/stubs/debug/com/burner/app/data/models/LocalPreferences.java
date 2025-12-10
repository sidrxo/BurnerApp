package com.burner.app.data.models;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.PropertyName;

/**
 * Local preferences stored in DataStore
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000.\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0006\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u001b\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001BW\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u0004\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u0012\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u0007\u0012\b\b\u0002\u0010\t\u001a\u00020\n\u0012\b\b\u0002\u0010\u000b\u001a\u00020\n\u0012\b\b\u0002\u0010\f\u001a\u00020\n\u00a2\u0006\u0002\u0010\rJ\u000f\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000b\u0010\u001b\u001a\u0004\u0018\u00010\u0004H\u00c6\u0003J\u0010\u0010\u001c\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0013J\u0010\u0010\u001d\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0013J\t\u0010\u001e\u001a\u00020\nH\u00c6\u0003J\t\u0010\u001f\u001a\u00020\nH\u00c6\u0003J\t\u0010 \u001a\u00020\nH\u00c6\u0003J`\u0010!\u001a\u00020\u00002\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u00042\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00072\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u00072\b\b\u0002\u0010\t\u001a\u00020\n2\b\b\u0002\u0010\u000b\u001a\u00020\n2\b\b\u0002\u0010\f\u001a\u00020\nH\u00c6\u0001\u00a2\u0006\u0002\u0010\"J\u0013\u0010#\u001a\u00020\n2\b\u0010$\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010%\u001a\u00020&H\u00d6\u0001J\t\u0010\'\u001a\u00020\u0004H\u00d6\u0001R\u0011\u0010\u000b\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0011\u0010\t\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u000fR\u0011\u0010\f\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u000fR\u0015\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\n\n\u0002\u0010\u0014\u001a\u0004\b\u0012\u0010\u0013R\u0015\u0010\b\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\n\n\u0002\u0010\u0014\u001a\u0004\b\u0015\u0010\u0013R\u0013\u0010\u0005\u001a\u0004\u0018\u00010\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017R\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0019\u00a8\u0006("}, d2 = {"Lcom/burner/app/data/models/LocalPreferences;", "", "selectedGenres", "", "", "locationName", "locationLat", "", "locationLon", "hasEnabledNotifications", "", "hasCompletedOnboarding", "hasSeenWelcome", "(Ljava/util/List;Ljava/lang/String;Ljava/lang/Double;Ljava/lang/Double;ZZZ)V", "getHasCompletedOnboarding", "()Z", "getHasEnabledNotifications", "getHasSeenWelcome", "getLocationLat", "()Ljava/lang/Double;", "Ljava/lang/Double;", "getLocationLon", "getLocationName", "()Ljava/lang/String;", "getSelectedGenres", "()Ljava/util/List;", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "copy", "(Ljava/util/List;Ljava/lang/String;Ljava/lang/Double;Ljava/lang/Double;ZZZ)Lcom/burner/app/data/models/LocalPreferences;", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class LocalPreferences {
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<java.lang.String> selectedGenres = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String locationName = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double locationLat = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double locationLon = null;
    private final boolean hasEnabledNotifications = false;
    private final boolean hasCompletedOnboarding = false;
    private final boolean hasSeenWelcome = false;
    
    public LocalPreferences(@org.jetbrains.annotations.NotNull()
    java.util.List<java.lang.String> selectedGenres, @org.jetbrains.annotations.Nullable()
    java.lang.String locationName, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLon, boolean hasEnabledNotifications, boolean hasCompletedOnboarding, boolean hasSeenWelcome) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<java.lang.String> getSelectedGenres() {
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
    
    public final boolean getHasEnabledNotifications() {
        return false;
    }
    
    public final boolean getHasCompletedOnboarding() {
        return false;
    }
    
    public final boolean getHasSeenWelcome() {
        return false;
    }
    
    public LocalPreferences() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<java.lang.String> component1() {
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
    
    public final boolean component6() {
        return false;
    }
    
    public final boolean component7() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.LocalPreferences copy(@org.jetbrains.annotations.NotNull()
    java.util.List<java.lang.String> selectedGenres, @org.jetbrains.annotations.Nullable()
    java.lang.String locationName, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLon, boolean hasEnabledNotifications, boolean hasCompletedOnboarding, boolean hasSeenWelcome) {
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