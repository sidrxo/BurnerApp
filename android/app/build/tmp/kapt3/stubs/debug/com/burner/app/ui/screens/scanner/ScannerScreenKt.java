package com.burner.app.ui.screens.scanner;

import android.Manifest;
import android.util.Size;
import androidx.camera.core.*;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.material.icons.filled.*;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.text.style.TextAlign;
import androidx.core.content.ContextCompat;
import com.burner.app.ui.theme.BurnerColors;
import com.burner.app.ui.theme.BurnerDimensions;
import com.burner.app.ui.theme.BurnerTypography;
import com.google.accompanist.permissions.ExperimentalPermissionsApi;
import com.google.accompanist.permissions.PermissionState;
import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;
import com.google.mlkit.vision.common.InputImage;
import java.util.concurrent.Executors;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000T\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\u001a\u0010\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u0003H\u0003\u001a\u001c\u0010\u0004\u001a\u00020\u00012\u0012\u0010\u0005\u001a\u000e\u0012\u0004\u0012\u00020\u0007\u0012\u0004\u0012\u00020\u00010\u0006H\u0003\u001a>\u0010\b\u001a\u00020\u00012\f\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\n2\b\u0010\f\u001a\u0004\u0018\u00010\u00072\u0012\u0010\r\u001a\u000e\u0012\u0004\u0012\u00020\u0007\u0012\u0004\u0012\u00020\u00010\u00062\b\b\u0002\u0010\u000e\u001a\u00020\u000fH\u0003\u001a:\u0010\u0010\u001a\u00020\u00012\u0006\u0010\u0011\u001a\u00020\u00072\u0012\u0010\u0012\u001a\u000e\u0012\u0004\u0012\u00020\u0007\u0012\u0004\u0012\u00020\u00010\u00062\f\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\u00010\u00142\u0006\u0010\u0015\u001a\u00020\u0016H\u0003\u001a\b\u0010\u0017\u001a\u00020\u0001H\u0003\u001a\u001e\u0010\u0018\u001a\u00020\u00012\u0006\u0010\u0019\u001a\u00020\u001a2\f\u0010\u001b\u001a\b\u0012\u0004\u0012\u00020\u00010\u0014H\u0003\u001a\u0018\u0010\u001c\u001a\u00020\u00012\u0006\u0010\u001d\u001a\u00020\u001e2\u0006\u0010\u001f\u001a\u00020 H\u0003\u001a \u0010!\u001a\u00020\u00012\f\u0010\"\u001a\b\u0012\u0004\u0012\u00020\u00010\u00142\b\b\u0002\u0010\u001f\u001a\u00020 H\u0007\u00a8\u0006#"}, d2 = {"CameraPermissionView", "", "permissionState", "Lcom/google/accompanist/permissions/PermissionState;", "CameraPreview", "onQRCodeScanned", "Lkotlin/Function1;", "", "EventSelector", "events", "", "Lcom/burner/app/data/models/Event;", "selectedEventId", "onEventSelected", "modifier", "Landroidx/compose/ui/Modifier;", "ManualEntryView", "value", "onValueChange", "onSubmit", "Lkotlin/Function0;", "isProcessing", "", "NoAccessView", "ScanResultView", "result", "Lcom/burner/app/ui/screens/scanner/ScanResult;", "onDismiss", "ScannerContent", "uiState", "Lcom/burner/app/ui/screens/scanner/ScannerUiState;", "viewModel", "Lcom/burner/app/ui/screens/scanner/ScannerViewModel;", "ScannerScreen", "onBackClick", "app_debug"})
public final class ScannerScreenKt {
    
    @kotlin.OptIn(markerClass = {com.google.accompanist.permissions.ExperimentalPermissionsApi.class})
    @androidx.compose.runtime.Composable()
    public static final void ScannerScreen(@org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function0<kotlin.Unit> onBackClick, @org.jetbrains.annotations.NotNull()
    com.burner.app.ui.screens.scanner.ScannerViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void NoAccessView() {
    }
    
    @kotlin.OptIn(markerClass = {com.google.accompanist.permissions.ExperimentalPermissionsApi.class})
    @androidx.compose.runtime.Composable()
    private static final void CameraPermissionView(com.google.accompanist.permissions.PermissionState permissionState) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void ScannerContent(com.burner.app.ui.screens.scanner.ScannerUiState uiState, com.burner.app.ui.screens.scanner.ScannerViewModel viewModel) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable()
    private static final void EventSelector(java.util.List<com.burner.app.data.models.Event> events, java.lang.String selectedEventId, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onEventSelected, androidx.compose.ui.Modifier modifier) {
    }
    
    @androidx.annotation.OptIn(markerClass = {androidx.camera.core.ExperimentalGetImage.class})
    @androidx.compose.runtime.Composable()
    private static final void CameraPreview(kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onQRCodeScanned) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void ManualEntryView(java.lang.String value, kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onValueChange, kotlin.jvm.functions.Function0<kotlin.Unit> onSubmit, boolean isProcessing) {
    }
    
    @androidx.compose.runtime.Composable()
    private static final void ScanResultView(com.burner.app.ui.screens.scanner.ScanResult result, kotlin.jvm.functions.Function0<kotlin.Unit> onDismiss) {
    }
}