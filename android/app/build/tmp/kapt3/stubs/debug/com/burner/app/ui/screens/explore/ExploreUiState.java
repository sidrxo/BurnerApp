package com.burner.app.ui.screens.explore;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.PreferencesRepository;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\"\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0015\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001B[\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\u000e\b\u0002\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\b\u0012\b\b\u0002\u0010\n\u001a\u00020\u000b\u0012\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\t\u00a2\u0006\u0002\u0010\rJ\u000f\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000f\u0010\u0018\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000f\u0010\u0019\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\u000f\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\t0\bH\u00c6\u0003J\t\u0010\u001b\u001a\u00020\u000bH\u00c6\u0003J\u000b\u0010\u001c\u001a\u0004\u0018\u00010\tH\u00c6\u0003J_\u0010\u001d\u001a\u00020\u00002\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u000e\b\u0002\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\b2\b\b\u0002\u0010\n\u001a\u00020\u000b2\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\tH\u00c6\u0001J\u0013\u0010\u001e\u001a\u00020\u000b2\b\u0010\u001f\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010 \u001a\u00020!H\u00d6\u0001J\t\u0010\"\u001a\u00020\tH\u00d6\u0001R\u0017\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0013\u0010\f\u001a\u0004\u0018\u00010\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013R\u0011\u0010\n\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u0014R\u0017\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0013R\u0017\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0013\u00a8\u0006#"}, d2 = {"Lcom/burner/app/ui/screens/explore/ExploreUiState;", "", "featuredEvents", "", "Lcom/burner/app/data/models/Event;", "thisWeekEvents", "nearbyEvents", "bookmarkedEventIds", "", "", "isLoading", "", "error", "(Ljava/util/List;Ljava/util/List;Ljava/util/List;Ljava/util/Set;ZLjava/lang/String;)V", "getBookmarkedEventIds", "()Ljava/util/Set;", "getError", "()Ljava/lang/String;", "getFeaturedEvents", "()Ljava/util/List;", "()Z", "getNearbyEvents", "getThisWeekEvents", "component1", "component2", "component3", "component4", "component5", "component6", "copy", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class ExploreUiState {
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> featuredEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> thisWeekEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> nearbyEvents = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.Set<java.lang.String> bookmarkedEventIds = null;
    private final boolean isLoading = false;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String error = null;
    
    public ExploreUiState(@org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> featuredEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> thisWeekEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> nearbyEvents, @org.jetbrains.annotations.NotNull()
    java.util.Set<java.lang.String> bookmarkedEventIds, boolean isLoading, @org.jetbrains.annotations.Nullable()
    java.lang.String error) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> getFeaturedEvents() {
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
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component2() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component3() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.Set<java.lang.String> component4() {
        return null;
    }
    
    public final boolean component5() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component6() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.explore.ExploreUiState copy(@org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> featuredEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> thisWeekEvents, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> nearbyEvents, @org.jetbrains.annotations.NotNull()
    java.util.Set<java.lang.String> bookmarkedEventIds, boolean isLoading, @org.jetbrains.annotations.Nullable()
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