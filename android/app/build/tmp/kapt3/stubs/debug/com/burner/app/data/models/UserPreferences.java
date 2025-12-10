package com.burner.app.data.models;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.PropertyName;

/**
 * User preferences stored in Firestore
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000.\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0006\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0018\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001BM\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u0004\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u0012\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u0007\u0012\b\b\u0002\u0010\t\u001a\u00020\n\u0012\b\b\u0002\u0010\u000b\u001a\u00020\n\u00a2\u0006\u0002\u0010\fJ\u000f\u0010\u0018\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000b\u0010\u0019\u001a\u0004\u0018\u00010\u0004H\u00c6\u0003J\u0010\u0010\u001a\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0011J\u0010\u0010\u001b\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0011J\t\u0010\u001c\u001a\u00020\nH\u00c6\u0003J\t\u0010\u001d\u001a\u00020\nH\u00c6\u0003JV\u0010\u001e\u001a\u00020\u00002\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u00042\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00072\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u00072\b\b\u0002\u0010\t\u001a\u00020\n2\b\b\u0002\u0010\u000b\u001a\u00020\nH\u00c6\u0001\u00a2\u0006\u0002\u0010\u001fJ\u0013\u0010 \u001a\u00020\n2\b\u0010!\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\"\u001a\u00020#H\u00d6\u0001J\t\u0010$\u001a\u00020\u0004H\u00d6\u0001R\u0016\u0010\u000b\u001a\u00020\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u0016\u0010\t\u001a\u00020\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u000eR\u001a\u0010\u0006\u001a\u0004\u0018\u00010\u00078\u0006X\u0087\u0004\u00a2\u0006\n\n\u0002\u0010\u0012\u001a\u0004\b\u0010\u0010\u0011R\u001a\u0010\b\u001a\u0004\u0018\u00010\u00078\u0006X\u0087\u0004\u00a2\u0006\n\n\u0002\u0010\u0012\u001a\u0004\b\u0013\u0010\u0011R\u0018\u0010\u0005\u001a\u0004\u0018\u00010\u00048\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015R\u001c\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017\u00a8\u0006%"}, d2 = {"Lcom/burner/app/data/models/UserPreferences;", "", "selectedGenres", "", "", "locationName", "locationLat", "", "locationLon", "hasEnabledNotifications", "", "hasCompletedOnboarding", "(Ljava/util/List;Ljava/lang/String;Ljava/lang/Double;Ljava/lang/Double;ZZ)V", "getHasCompletedOnboarding", "()Z", "getHasEnabledNotifications", "getLocationLat", "()Ljava/lang/Double;", "Ljava/lang/Double;", "getLocationLon", "getLocationName", "()Ljava/lang/String;", "getSelectedGenres", "()Ljava/util/List;", "component1", "component2", "component3", "component4", "component5", "component6", "copy", "(Ljava/util/List;Ljava/lang/String;Ljava/lang/Double;Ljava/lang/Double;ZZ)Lcom/burner/app/data/models/UserPreferences;", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class UserPreferences {
    @com.google.firebase.firestore.PropertyName(value = "selectedGenres")
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<java.lang.String> selectedGenres = null;
    @com.google.firebase.firestore.PropertyName(value = "locationName")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String locationName = null;
    @com.google.firebase.firestore.PropertyName(value = "locationLat")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double locationLat = null;
    @com.google.firebase.firestore.PropertyName(value = "locationLon")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double locationLon = null;
    @com.google.firebase.firestore.PropertyName(value = "hasEnabledNotifications")
    private final boolean hasEnabledNotifications = false;
    @com.google.firebase.firestore.PropertyName(value = "hasCompletedOnboarding")
    private final boolean hasCompletedOnboarding = false;
    
    public UserPreferences(@org.jetbrains.annotations.NotNull()
    java.util.List<java.lang.String> selectedGenres, @org.jetbrains.annotations.Nullable()
    java.lang.String locationName, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLon, boolean hasEnabledNotifications, boolean hasCompletedOnboarding) {
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
    
    public UserPreferences() {
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
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.UserPreferences copy(@org.jetbrains.annotations.NotNull()
    java.util.List<java.lang.String> selectedGenres, @org.jetbrains.annotations.Nullable()
    java.lang.String locationName, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double locationLon, boolean hasEnabledNotifications, boolean hasCompletedOnboarding) {
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