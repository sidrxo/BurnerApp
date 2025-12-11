package com.burner.app.ui.screens.scanner

import android.Manifest
import android.util.Size
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import com.burner.app.ui.components.BurnerTopBar
import com.burner.app.ui.components.PrimaryButton
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.PermissionState
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.Executors

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun ScannerScreen(
    onBackClick: () -> Unit,
    viewModel: ScannerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val cameraPermissionState = rememberPermissionState(Manifest.permission.CAMERA)

    LaunchedEffect(Unit) {
        if (!cameraPermissionState.status.isGranted) {
            cameraPermissionState.launchPermissionRequest()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "SCANNER",
            onBackClick = onBackClick
        )

        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = BurnerColors.Primary)
                }
            }
            !uiState.canAccessScanner -> {
                NoAccessView()
            }
            !cameraPermissionState.status.isGranted -> {
                CameraPermissionView(cameraPermissionState)
            }
            else -> {
                ScannerContent(
                    uiState = uiState,
                    viewModel = viewModel
                )
            }
        }
    }
}

@Composable
private fun NoAccessView() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(BurnerDimensions.paddingScreen)
        ) {
            Icon(
                imageVector = Icons.Filled.Lock,
                contentDescription = null,
                tint = BurnerColors.TextDimmed,
                modifier = Modifier.size(64.dp)
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))
            Text(
                text = "Access Denied",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))
            Text(
                text = "You don't have permission to use the scanner",
                style = BurnerTypography.body,
                color = BurnerColors.TextSecondary,
                textAlign = TextAlign.Center
            )
        }
    }
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
private fun CameraPermissionView(permissionState: PermissionState) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(BurnerDimensions.paddingScreen)
        ) {
            Icon(
                imageVector = Icons.Filled.CameraAlt,
                contentDescription = null,
                tint = BurnerColors.TextDimmed,
                modifier = Modifier.size(64.dp)
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))
            Text(
                text = "Camera Permission Required",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))
            Text(
                text = "We need camera access to scan QR codes on tickets",
                style = BurnerTypography.body,
                color = BurnerColors.TextSecondary,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))
            PrimaryButton(
                text = "Grant Permission",
                onClick = { permissionState.launchPermissionRequest() }
            )
        }
    }
}

@Composable
private fun ScannerContent(
    uiState: ScannerUiState,
    viewModel: ScannerViewModel
) {
    var isScanning by remember { mutableStateOf(true) }

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Event Selector
        if (uiState.availableEvents.isNotEmpty()) {
            EventSelector(
                events = uiState.availableEvents,
                selectedEventId = uiState.selectedEventId,
                onEventSelected = { viewModel.selectEvent(it) },
                modifier = Modifier.padding(BurnerDimensions.paddingScreen)
            )
        }

        // Camera Preview or Manual Entry
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
        ) {
            if (isScanning && !uiState.isProcessing) {
                CameraPreview(
                    onQRCodeScanned = { qrCode ->
                        viewModel.scanQRCode(qrCode)
                    }
                )

                // Viewfinder overlay
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(250.dp)
                            .border(
                                width = 3.dp,
                                color = BurnerColors.Primary,
                                shape = RoundedCornerShape(16.dp)
                            )
                    )
                }
            } else {
                ManualEntryView(
                    value = uiState.manualEntry,
                    onValueChange = { viewModel.updateManualEntry(it) },
                    onSubmit = { viewModel.scanManualEntry() },
                    isProcessing = uiState.isProcessing
                )
            }
        }

        // Scan/Manual Toggle
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = BurnerDimensions.paddingScreen),
            horizontalArrangement = Arrangement.Center
        ) {
            TextButton(
                onClick = { isScanning = !isScanning },
                enabled = !uiState.isProcessing
            ) {
                Icon(
                    imageVector = if (isScanning) Icons.Filled.Keyboard else Icons.Filled.QrCodeScanner,
                    contentDescription = null,
                    tint = BurnerColors.Primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isScanning) "Manual Entry" else "Scan QR Code",
                    color = BurnerColors.Primary
                )
            }
        }

        // Scan Result
        uiState.scanResult?.let { result ->
            ScanResultView(
                result = result,
                onDismiss = { viewModel.clearScanResult() }
            )
        }

        // Error Message
        uiState.errorMessage?.let { error ->
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(BurnerDimensions.paddingScreen),
                color = BurnerColors.Error.copy(alpha = 0.1f),
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier.padding(BurnerDimensions.paddingCard),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Filled.Error,
                        contentDescription = null,
                        tint = BurnerColors.Error
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = error,
                        style = BurnerTypography.body,
                        color = BurnerColors.Error,
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = { viewModel.clearError() }) {
                        Icon(
                            imageVector = Icons.Filled.Close,
                            contentDescription = "Dismiss",
                            tint = BurnerColors.Error
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EventSelector(
    events: List<com.burner.app.data.models.Event>,
    selectedEventId: String?,
    onEventSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedEvent = events.find { it.id == selectedEventId }

    Column(modifier = modifier) {
        Text(
            text = "SELECT EVENT",
            style = BurnerTypography.caption,
            color = BurnerColors.TextDimmed
        )
        Spacer(modifier = Modifier.height(4.dp))
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = !expanded }
        ) {
            OutlinedTextField(
                value = selectedEvent?.name ?: "Select an event",
                onValueChange = {},
                readOnly = true,
                trailingIcon = {
                    Icon(
                        imageVector = if (expanded) Icons.Filled.ArrowDropUp else Icons.Filled.ArrowDropDown,
                        contentDescription = null
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BurnerColors.Primary,
                    unfocusedBorderColor = BurnerColors.Border,
                    focusedTextColor = BurnerColors.TextPrimary,
                    unfocusedTextColor = BurnerColors.TextPrimary
                )
            )
            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                events.forEach { event ->
                    DropdownMenuItem(
                        text = { Text(event.name) },
                        onClick = {
                            event.id?.let { onEventSelected(it) }
                            expanded = false
                        }
                    )
                }
            }
        }
    }
}

@androidx.annotation.OptIn(ExperimentalGetImage::class)
@Composable
private fun CameraPreview(
    onQRCodeScanned: (String) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    val executor = remember { Executors.newSingleThreadExecutor() }
    var lastScannedCode by remember { mutableStateOf("") }
    var lastScannedTime by remember { mutableStateOf(0L) }

    AndroidView(
        factory = { ctx ->
            val previewView = PreviewView(ctx)
            val cameraProvider = cameraProviderFuture.get()
            val preview = Preview.Builder().build()
            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            preview.setSurfaceProvider(previewView.surfaceProvider)

            val imageAnalyzer = ImageAnalysis.Builder()
                .setTargetResolution(Size(1280, 720))
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()

            val barcodeScanner = BarcodeScanning.getClient()

            imageAnalyzer.setAnalyzer(executor) { imageProxy ->
                val mediaImage = imageProxy.image
                if (mediaImage != null) {
                    val image = InputImage.fromMediaImage(
                        mediaImage,
                        imageProxy.imageInfo.rotationDegrees
                    )

                    barcodeScanner.process(image)
                        .addOnSuccessListener { barcodes ->
                            for (barcode in barcodes) {
                                if (barcode.format == Barcode.FORMAT_QR_CODE) {
                                    val rawValue = barcode.rawValue
                                    if (rawValue != null) {
                                        val currentTime = System.currentTimeMillis()
                                        // Prevent duplicate scans within 2 seconds
                                        if (rawValue != lastScannedCode || currentTime - lastScannedTime > 2000) {
                                            lastScannedCode = rawValue
                                            lastScannedTime = currentTime
                                            onQRCodeScanned(rawValue)
                                        }
                                    }
                                }
                            }
                        }
                        .addOnCompleteListener {
                            imageProxy.close()
                        }
                } else {
                    imageProxy.close()
                }
            }

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    cameraSelector,
                    preview,
                    imageAnalyzer
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }

            previewView
        },
        modifier = Modifier.fillMaxSize()
    )
}

@Composable
private fun ManualEntryView(
    value: String,
    onValueChange: (String) -> Unit,
    onSubmit: () -> Unit,
    isProcessing: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(BurnerDimensions.paddingScreen),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Filled.ConfirmationNumber,
            contentDescription = null,
            tint = BurnerColors.TextDimmed,
            modifier = Modifier.size(64.dp)
        )
        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))
        Text(
            text = "Enter Ticket Number",
            style = BurnerTypography.sectionHeader,
            color = BurnerColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = { Text("TKT1234567890") },
            enabled = !isProcessing,
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = BurnerColors.Primary,
                unfocusedBorderColor = BurnerColors.Border,
                focusedTextColor = BurnerColors.TextPrimary,
                unfocusedTextColor = BurnerColors.TextPrimary
            )
        )
        Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))
        PrimaryButton(
            text = if (isProcessing) "Scanning..." else "Scan",
            onClick = onSubmit,
            enabled = !isProcessing && value.isNotEmpty(),
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun ScanResultView(
    result: ScanResult,
    onDismiss: () -> Unit
) {
    val backgroundColor = when (result) {
        is ScanResult.Success -> BurnerColors.Success.copy(alpha = 0.1f)
        is ScanResult.AlreadyUsed -> Color(0xFFFF9800).copy(alpha = 0.1f)
        is ScanResult.Error -> BurnerColors.Error.copy(alpha = 0.1f)
    }

    val textColor = when (result) {
        is ScanResult.Success -> BurnerColors.Success
        is ScanResult.AlreadyUsed -> Color(0xFFFF9800)
        is ScanResult.Error -> BurnerColors.Error
    }

    val icon = when (result) {
        is ScanResult.Success -> Icons.Filled.CheckCircle
        is ScanResult.AlreadyUsed -> Icons.Filled.Warning
        is ScanResult.Error -> Icons.Filled.Error
        else -> Icons.Filled.Error
    }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(BurnerDimensions.paddingScreen),
        color = backgroundColor,
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(BurnerDimensions.spacingLg)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = textColor,
                    modifier = Modifier.size(32.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    when (result) {
                        is ScanResult.Success -> {
                            Text(
                                text = "Ticket Scanned Successfully",
                                style = BurnerTypography.card,
                                color = textColor
                            )
                            Text(
                                text = "${result.ticketNumber} • ${result.eventName}",
                                style = BurnerTypography.body,
                                color = textColor.copy(alpha = 0.8f)
                            )
                        }
                        is ScanResult.AlreadyUsed -> {
                            Text(
                                text = "Ticket Already Used",
                                style = BurnerTypography.card,
                                color = textColor
                            )
                            Text(
                                text = "${result.ticketNumber} • Scanned at ${result.scannedAt}",
                                style = BurnerTypography.body,
                                color = textColor.copy(alpha = 0.8f)
                            )
                        }
                        is ScanResult.Error -> {
                            Text(
                                text = "Scan Failed",
                                style = BurnerTypography.card,
                                color = textColor
                            )
                            Text(
                                text = result.message,
                                style = BurnerTypography.body,
                                color = textColor.copy(alpha = 0.8f)
                            )
                        }
                    }
                }
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = "Dismiss",
                        tint = textColor
                    )
                }
            }
        }
    }
}
