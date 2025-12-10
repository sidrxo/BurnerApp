package com.burner.app.ui.screens.explore;

import android.util.Log;
import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.PreferencesRepository;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import java.util.Calendar;
import java.util.Date;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00008\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\"\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0006\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b \n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001B\u0093\u0001\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\n\u0012\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\r\u0012\n\b\u0002\u0010\u000e\u001a\u0004\u0018\u00010\r\u0012\b\b\u0002\u0010\u000f\u001a\u00020\u0010\u0012\n\b\u0002\u0010\u0011\u001a\u0004\u0018\u00010\u000b\u00a2\u0006\u0002\u0010\u0012J\u000f\u0010\"\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000b\u0010#\u001a\u0004\u0018\u00010\u000bH\u00c6\u0003J\u000f\u0010$\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000f\u0010%\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000f\u0010&\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000f\u0010\'\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000f\u0010(\u001a\b\u0012\u0004\u0012\u00020\u000b0\nH\u00c6\u0003J\u0010\u0010)\u001a\u0004\u0018\u00010\rH\u00c6\u0003\u00a2\u0006\u0002\u0010\u001fJ\u0010\u0010*\u001a\u0004\u0018\u00010\rH\u00c6\u0003\u00a2\u0006\u0002\u0010\u001fJ\t\u0010+\u001a\u00020\u0010H\u00c6\u0003J\u009c\u0001\u0010,\u001a\u00020\u00002\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\n2\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\r2\n\b\u0002\u0010\u000e\u001a\u0004\u0018\u00010\r2\b\b\u0002\u0010\u000f\u001a\u00020\u00102\n\b\u0002\u0010\u0011\u001a\u0004\u0018\u00010\u000bH\u00c6\u0001\u00a2\u0006\u0002\u0010-J\u0013\u0010.\u001a\u00020\u00102\b\u0010/\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u00100\u001a\u000201H\u00d6\u0001J\t\u00102\u001a\u00020\u000bH\u00d6\u0001R\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014R\u0017\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0016R\u0013\u0010\u0011\u001a\u0004\u0018\u00010\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0018R\u0017\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u0014R\u0011\u0010\u000f\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u001aR\u0017\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0014R\u0017\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u0014R\u0017\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u0014R\u0015\u0010\f\u001a\u0004\u0018\u00010\r\u00a2\u0006\n\n\u0002\u0010 \u001a\u0004\b\u001e\u0010\u001fR\u0015\u0010\u000e\u001a\u0004\u0018\u00010\r\u00a2\u0006\n\n\u0002\u0010 \u001a\u0004\b!\u0010\u001f\u00a8\u00063"}, d2 = {"Lcom/burner/app/ui/screens/explore/ExploreUiState;", "", "allEvents", "", "Lcom/burner/app/data/models/Event;", "featuredEvents", "popularEvents", "thisWeekEvents", "nearbyEvents", "bookmarkedEventIds", "", "", "userLat", "", "userLon", "isLoading", "", "error", "(Ljava/util/List;Ljava/util/List;Ljava/util/List;Ljava/util/List;Ljava/util/List;Ljava/util/Set;Ljava/lang/Double;Ljava/lang/Double;ZLjava/lang/String;)V", "getAllEvents", "()Ljava/util/List;", "getBookmarkedEventIds", "()Ljava/util/Set;", "getError", "()Ljava/lang/String;", "getFeaturedEvents", "()Z", "getNearbyEvents", "getPopularEvents", "getThisWeekEvents", "getUserLat", "()Ljava/lang/Double;", "Ljava/lang/Double;", "getUserLon", "component1", "component10", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "(Ljava/util/List;Ljava/util/List;Ljava/util/List;Ljava/util/List;Ljava/util/List;Ljava/util/Set;Ljava/lang/Double;Ljava/lang/Double;ZLjava/lang/String;)Lcom/burner/app/ui/screens/explore/ExploreUiState;", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class ExploreUiState {
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> allEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> featuredEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> popularEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> thisWeekEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> nearbyEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.Set<java.lang.String> bookmarkedEventIds = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double userLat = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double userLon = null;
    private final boolean isLoading = false;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String error = null;
    
    public ExploreUiState(@org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> allEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> featuredEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> popularEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> thisWeekEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> nearbyEvents, @org.jetbrains.annotations.NotNull()
    java.util.Set<java.lang.String> bookmarkedEventIds, @org.jetbrains.annotations.Nullable()
    java.lang.Double userLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double userLon, boolean isLoading, @org.jetbrains.annotations.Nullable()
    java.lang.String error) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> getAllEvents() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> getFeaturedEvents() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> getPopularEvents() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> getThisWeekEvents() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> getNearbyEvents() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.Set<java.lang.String> getBookmarkedEventIds() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double getUserLat() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double getUserLon() {
        return null;
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getError() {
        return null;
    }
    
    public ExploreUiState() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component1() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component10() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component2() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component3() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component5() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.Set<java.lang.String> component6() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double component7() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double component8() {
        return null;
    }
    
    public final boolean component9() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.explore.ExploreUiState copy(@org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> allEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> featuredEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> popularEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> thisWeekEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> nearbyEvents, @org.jetbrains.annotations.NotNull()
    java.util.Set<java.lang.String> bookmarkedEventIds, @org.jetbrains.annotations.Nullable()
    java.lang.Double userLat, @org.jetbrains.annotations.Nullable()
    java.lang.Double userLon, boolean isLoading, @org.jetbrains.annotations.Nullable()
    java.lang.String error) {
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