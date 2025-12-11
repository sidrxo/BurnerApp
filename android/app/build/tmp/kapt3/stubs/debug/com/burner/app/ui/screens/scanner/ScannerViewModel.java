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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000N\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010$\n\u0002\b\f\b\u0007\u0018\u00002\u00020\u0001B\'\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u0012\u0006\u0010\b\u001a\u00020\t\u00a2\u0006\u0002\u0010\nJ\b\u0010\u0012\u001a\u00020\u0013H\u0002J\u0006\u0010\u0014\u001a\u00020\u0013J\u0006\u0010\u0015\u001a\u00020\u0013J\u0012\u0010\u0016\u001a\u0004\u0018\u00010\u00172\u0006\u0010\u0018\u001a\u00020\u0017H\u0002J\u001a\u0010\u0019\u001a\u00020\u00172\u0010\u0010\u001a\u001a\f\u0012\u0002\b\u0003\u0012\u0002\b\u0003\u0018\u00010\u001bH\u0002J\u001a\u0010\u001c\u001a\u00020\u00132\u0010\u0010\u001d\u001a\f\u0012\u0002\b\u0003\u0012\u0002\b\u0003\u0018\u00010\u001bH\u0002J\u0018\u0010\u001e\u001a\u00020\u00132\b\u0010\u001f\u001a\u0004\u0018\u00010\u0017H\u0082@\u00a2\u0006\u0002\u0010 J\u0006\u0010!\u001a\u00020\u0013J\u000e\u0010\"\u001a\u00020\u00132\u0006\u0010\u0018\u001a\u00020\u0017J\u000e\u0010#\u001a\u00020\u00132\u0006\u0010$\u001a\u00020\u0017J\u000e\u0010%\u001a\u00020\u00132\u0006\u0010&\u001a\u00020\u0017R\u0014\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\r0\fX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\tX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\r0\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011\u00a8\u0006\'"}, d2 = {"Lcom/burner/app/ui/screens/scanner/ScannerViewModel;", "Landroidx/lifecycle/ViewModel;", "authService", "Lcom/burner/app/services/AuthService;", "eventRepository", "Lcom/burner/app/data/repository/EventRepository;", "firestore", "Lcom/google/firebase/firestore/FirebaseFirestore;", "functions", "Lcom/google/firebase/functions/FirebaseFunctions;", "(Lcom/burner/app/services/AuthService;Lcom/burner/app/data/repository/EventRepository;Lcom/google/firebase/firestore/FirebaseFirestore;Lcom/google/firebase/functions/FirebaseFunctions;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/scanner/ScannerUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "checkScannerAccess", "", "clearError", "clearScanResult", "extractTicketId", "", "qrCodeData", "formatTimestamp", "timestamp", "", "handleScanResult", "resultData", "loadTodayEvents", "userRole", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "scanManualEntry", "scanQRCode", "selectEvent", "eventId", "updateManualEntry", "value", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class ScannerViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.EventRepository eventRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.firestore.FirebaseFirestore firestore = null;
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.functions.FirebaseFunctions functions = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.scanner.ScannerUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.scanner.ScannerUiState> uiState = null;
    
    @javax.inject.Inject()
    public ScannerViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.services.AuthService authService, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.EventRepository eventRepository, @org.jetbrains.annotations.NotNull()
    com.google.firebase.firestore.FirebaseFirestore firestore, @org.jetbrains.annotations.NotNull()
    com.google.firebase.functions.FirebaseFunctions functions) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.scanner.ScannerUiState> getUiState() {
        return null;
    }
    
    private final void checkScannerAccess() {
    }
    
    private final java.lang.Object loadTodayEvents(java.lang.String userRole, kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    public final void selectEvent(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId) {
    }
    
    public final void updateManualEntry(@org.jetbrains.annotations.NotNull()
    java.lang.String value) {
    }
    
    public final void scanQRCode(@org.jetbrains.annotations.NotNull()
    java.lang.String qrCodeData) {
    }
    
    public final void scanManualEntry() {
    }
    
    private final void handleScanResult(java.util.Map<?, ?> resultData) {
    }
    
    private final java.lang.String extractTicketId(java.lang.String qrCodeData) {
        return null;
    }
    
    private final java.lang.String formatTimestamp(java.util.Map<?, ?> timestamp) {
        return null;
    }
    
    public final void clearScanResult() {
    }
    
    public final void clearError() {
    }
}