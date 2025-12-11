package com.burner.app.ui.screens.scanner;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.models.UserRole;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.services.AuthService;
import com.google.firebase.Timestamp;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.functions.FirebaseFunctions;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import org.json.JSONObject;
import java.util.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0019\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001Ba\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u0012\u000e\b\u0002\u0010\b\u001a\b\u0012\u0004\u0012\u00020\n0\t\u0012\n\b\u0002\u0010\u000b\u001a\u0004\u0018\u00010\f\u0012\b\b\u0002\u0010\r\u001a\u00020\u0007\u0012\n\b\u0002\u0010\u000e\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\u0002\u0010\u000fJ\t\u0010\u001a\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u001b\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u001c\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010\u001d\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003J\u000f\u0010\u001e\u001a\b\u0012\u0004\u0012\u00020\n0\tH\u00c6\u0003J\u000b\u0010\u001f\u001a\u0004\u0018\u00010\fH\u00c6\u0003J\t\u0010 \u001a\u00020\u0007H\u00c6\u0003J\u000b\u0010!\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003Je\u0010\"\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00032\b\b\u0002\u0010\u0005\u001a\u00020\u00032\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00072\u000e\b\u0002\u0010\b\u001a\b\u0012\u0004\u0012\u00020\n0\t2\n\b\u0002\u0010\u000b\u001a\u0004\u0018\u00010\f2\b\b\u0002\u0010\r\u001a\u00020\u00072\n\b\u0002\u0010\u000e\u001a\u0004\u0018\u00010\u0007H\u00c6\u0001J\u0013\u0010#\u001a\u00020\u00032\b\u0010$\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010%\u001a\u00020&H\u00d6\u0001J\t\u0010\'\u001a\u00020\u0007H\u00d6\u0001R\u0017\u0010\b\u001a\b\u0012\u0004\u0012\u00020\n0\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0011\u0010\u0005\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013R\u0013\u0010\u000e\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0002\u0010\u0013R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0004\u0010\u0013R\u0011\u0010\r\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0015R\u0013\u0010\u000b\u001a\u0004\u0018\u00010\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0018R\u0013\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u0015\u00a8\u0006("}, d2 = {"Lcom/burner/app/ui/screens/scanner/ScannerUiState;", "", "isLoading", "", "isProcessing", "canAccessScanner", "selectedEventId", "", "availableEvents", "", "Lcom/burner/app/data/models/Event;", "scanResult", "Lcom/burner/app/ui/screens/scanner/ScanResult;", "manualEntry", "errorMessage", "(ZZZLjava/lang/String;Ljava/util/List;Lcom/burner/app/ui/screens/scanner/ScanResult;Ljava/lang/String;Ljava/lang/String;)V", "getAvailableEvents", "()Ljava/util/List;", "getCanAccessScanner", "()Z", "getErrorMessage", "()Ljava/lang/String;", "getManualEntry", "getScanResult", "()Lcom/burner/app/ui/screens/scanner/ScanResult;", "getSelectedEventId", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "copy", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class ScannerUiState {
    private final boolean isLoading = false;
    private final boolean isProcessing = false;
    private final boolean canAccessScanner = false;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String selectedEventId = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.burner.app.data.models.Event> availableEvents = null;
    @org.jetbrains.annotations.Nullable()
    private final com.burner.app.ui.screens.scanner.ScanResult scanResult = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String manualEntry = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String errorMessage = null;
    
    public ScannerUiState(boolean isLoading, boolean isProcessing, boolean canAccessScanner, @org.jetbrains.annotations.Nullable()
    java.lang.String selectedEventId, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> availableEvents, @org.jetbrains.annotations.Nullable()
    com.burner.app.ui.screens.scanner.ScanResult scanResult, @org.jetbrains.annotations.NotNull()
    java.lang.String manualEntry, @org.jetbrains.annotations.Nullable()
    java.lang.String errorMessage) {
        super();
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    public final boolean isProcessing() {
        return false;
    }
    
    public final boolean getCanAccessScanner() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getSelectedEventId() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> getAvailableEvents() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.ui.screens.scanner.ScanResult getScanResult() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getManualEntry() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getErrorMessage() {
        return null;
    }
    
    public ScannerUiState() {
        super();
    }
    
    public final boolean component1() {
        return false;
    }
    
    public final boolean component2() {
        return false;
    }
    
    public final boolean component3() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.burner.app.data.models.Event> component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.ui.screens.scanner.ScanResult component6() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component7() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component8() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.ui.screens.scanner.ScannerUiState copy(boolean isLoading, boolean isProcessing, boolean canAccessScanner, @org.jetbrains.annotations.Nullable()
    java.lang.String selectedEventId, @org.jetbrains.annotations.NotNull()
    java.util.List<com.burner.app.data.models.Event> availableEvents, @org.jetbrains.annotations.Nullable()
    com.burner.app.ui.screens.scanner.ScanResult scanResult, @org.jetbrains.annotations.NotNull()
    java.lang.String manualEntry, @org.jetbrains.annotations.Nullable()
    java.lang.String errorMessage) {
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