package com.burner.app.ui.screens.onboarding

import android.Manifest
import android.os.Build
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerTypography
import kotlinx.coroutines.delay

enum class OnboardingStep {
    WELCOME,
    LOCATION,
    GENRES,
    NOTIFICATIONS,
    COMPLETE
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun OnboardingFlowScreen(
    onComplete: () -> Unit,
    onSignIn: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Permission states
    val locationPermissionState = rememberPermissionState(Manifest.permission.ACCESS_FINE_LOCATION)
    val notificationPermissionState = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        rememberPermissionState(Manifest.permission.POST_NOTIFICATIONS)
    } else {
        null
    }

    // Auto-advance from complete step
    LaunchedEffect(uiState.currentStep) {
        if (uiState.currentStep == OnboardingStep.COMPLETE) {
            delay(1000)
            onComplete()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Header with back, progress, and skip
            OnboardingHeader(
                currentStep = uiState.currentStep,
                progressStep = uiState.progressStep,
                totalSteps = uiState.totalFlowSteps,
                showBackButton = uiState.showBackButton,
                showSkipButton = uiState.showSkipButton,
                onBack = { viewModel.previousStep() },
                onSkip = { viewModel.skipStep() }
            )

            // Content
            AnimatedContent(
                targetState = uiState.currentStep,
                modifier = Modifier.weight(1f),
                transitionSpec = {
                    fadeIn() + slideInHorizontally { it } togetherWith
                            fadeOut() + slideOutHorizontally { -it }
                },
                label = "onboarding_transition"
            ) { step ->
                when (step) {
                    OnboardingStep.WELCOME -> WelcomeStep(
                        eventImageUrls = uiState.eventImageUrls,
                        onSignIn = onSignIn,
                        onExplore = { viewModel.nextStep() }
                    )
                    OnboardingStep.LOCATION -> LocationStep(
                        locationName = uiState.locationName,
                        isLoading = uiState.isLoadingLocation,
                        onUseCurrentLocation = {
                            if (locationPermissionState.status.isGranted) {
                                viewModel.detectCurrentLocation()
                            } else {
                                locationPermissionState.launchPermissionRequest()
                            }
                        },
                        onManualEntry = { viewModel.setLocationManually(it) },
                        onContinue = { viewModel.nextStep() }
                    )
                    OnboardingStep.GENRES -> GenresStep(
                        genres = uiState.availableGenres,
                        selectedGenres = uiState.selectedGenres,
                        onGenreToggle = { viewModel.toggleGenre(it) },
                        onContinue = { viewModel.nextStep() }
                    )
                    OnboardingStep.NOTIFICATIONS -> NotificationsStep(
                        onEnable = {
                            notificationPermissionState?.launchPermissionRequest()
                            viewModel.setNotificationsEnabled(true)
                            viewModel.nextStep()
                        },
                        onSkip = {
                            viewModel.setNotificationsEnabled(false)
                            viewModel.nextStep()
                        }
                    )
                    OnboardingStep.COMPLETE -> CompleteStep()
                }
            }
        }
    }
}

@Composable
private fun OnboardingHeader(
    currentStep: OnboardingStep,
    progressStep: Int,
    totalSteps: Int,
    showBackButton: Boolean,
    showSkipButton: Boolean,
    onBack: () -> Unit,
    onSkip: () -> Unit
) {
    val showProgress = currentStep != OnboardingStep.WELCOME && currentStep != OnboardingStep.COMPLETE

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 16.dp)
            .height(60.dp)
    ) {
        // Back button (left)
        if (showBackButton) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.align(Alignment.CenterStart)
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = BurnerColors.White.copy(alpha = 0.6f)
                )
            }
        }

        // Progress indicator (center)
        if (showProgress) {
            ProgressLineView(
                currentStep = progressStep,
                totalSteps = totalSteps,
                modifier = Modifier.align(Alignment.Center)
            )
        }

        // Skip button (right)
        if (showSkipButton) {
            TextButton(
                onClick = onSkip,
                modifier = Modifier.align(Alignment.CenterEnd)
            ) {
                Text(
                    text = "SKIP",
                    style = BurnerTypography.secondary.copy(fontWeight = FontWeight.SemiBold),
                    color = BurnerColors.White.copy(alpha = 0.6f)
                )
            }
        }
    }
}

@Composable
private fun ProgressLineView(
    currentStep: Int,
    totalSteps: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.width(120.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        repeat(totalSteps) { index ->
            val isCompleted = index < currentStep
            val isCurrent = index == currentStep
            val progress by animateFloatAsState(
                targetValue = when {
                    isCompleted -> 1f
                    isCurrent -> 0.5f
                    else -> 0f
                },
                label = "progress"
            )

            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(2.dp)
                    .background(
                        color = if (isCompleted || isCurrent) BurnerColors.White else BurnerColors.White.copy(alpha = 0.2f),
                        shape = RoundedCornerShape(1.dp)
                    )
            )
        }
    }
}

// MARK: - Welcome Step with Event Mosaic
@Composable
private fun WelcomeStep(
    eventImageUrls: List<String>,
    onSignIn: () -> Unit,
    onExplore: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Event mosaic carousel
        if (eventImageUrls.isNotEmpty()) {
            EventMosaicCarousel(
                imageUrls = eventImageUrls,
                modifier = Modifier.padding(top = 24.dp)
            )
        } else {
            // Placeholder while loading
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(420.dp)
                    .padding(top = 24.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    color = BurnerColors.White,
                    strokeWidth = 2.dp
                )
            }
        }

        // Header text
        TightHeaderText(
            line1 = "MEET ME IN THE",
            line2 = "MOMENT",
            modifier = Modifier.padding(bottom = 22.dp)
        )

        // Buttons
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
            modifier = Modifier.padding(horizontal = 40.dp)
        ) {
            CapsuleButton(
                text = "SIGN UP/IN",
                isPrimary = true,
                onClick = onSignIn,
                modifier = Modifier.width(200.dp)
            )

            CapsuleButton(
                text = "EXPLORE",
                isPrimary = false,
                onClick = onExplore,
                modifier = Modifier.width(160.dp)
            )
        }

        Spacer(modifier = Modifier.weight(1f))
    }
}

// MARK: - Event Mosaic Carousel (matching iOS)
@Composable
private fun EventMosaicCarousel(
    imageUrls: List<String>,
    modifier: Modifier = Modifier
) {
    val rowOneImages = imageUrls.take(4)
    val rowTwoImages = imageUrls.drop(4).take(4)
    val rowThreeImages = imageUrls.drop(8).take(4)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(420.dp)
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier
                .rotate(-6f)
                .offset(x = 30.dp)
        ) {
            MosaicRow(imageUrls = rowOneImages)
            MosaicRow(imageUrls = rowTwoImages)
            MosaicRow(imageUrls = rowThreeImages)
        }

        // Gradient fade at bottom
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .align(Alignment.BottomCenter)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, BurnerColors.Background)
                    )
                )
        )
    }
}

@Composable
private fun MosaicRow(imageUrls: List<String>) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Spacer(modifier = Modifier.weight(1f))
        imageUrls.forEach { url ->
            MosaicCard(imageUrl = url)
        }
    }
}

@Composable
private fun MosaicCard(imageUrl: String) {
    AsyncImage(
        model = imageUrl,
        contentDescription = null,
        modifier = Modifier
            .size(134.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(BurnerColors.CardBackground),
        contentScale = ContentScale.Crop
    )
}

// MARK: - TightHeaderText (matching iOS)
@Composable
private fun TightHeaderText(
    line1: String,
    line2: String,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.height(120.dp),
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = line1,
            style = BurnerTypography.sectionHeader.copy(
                fontSize = 28.sp,
                letterSpacing = 2.sp
            ),
            color = BurnerColors.White
        )
        Text(
            text = line2,
            style = BurnerTypography.sectionHeader.copy(
                fontSize = 28.sp,
                letterSpacing = 2.sp
            ),
            color = BurnerColors.White
        )
    }
}

// MARK: - Capsule Button (matching iOS BurnerButton)
@Composable
private fun CapsuleButton(
    text: String,
    isPrimary: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    val backgroundColor = if (isPrimary) BurnerColors.White else Color.Transparent
    val textColor = if (isPrimary) BurnerColors.Black else BurnerColors.White
    val borderColor = if (isPrimary) Color.Transparent else BurnerColors.White

    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.height(48.dp),
        shape = CircleShape,
        color = backgroundColor,
        border = if (!isPrimary) androidx.compose.foundation.BorderStroke(1.dp, borderColor) else null
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                style = BurnerTypography.secondary.copy(
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                ),
                color = textColor
            )
        }
    }
}

// MARK: - Location Step
@Composable
private fun LocationStep(
    locationName: String?,
    isLoading: Boolean,
    onUseCurrentLocation: () -> Unit,
    onManualEntry: (String) -> Unit,
    onContinue: () -> Unit
) {
    var manualLocation by remember { mutableStateOf("") }
    var showManualInput by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        TightHeaderText(
            line1 = "WHERE ARE",
            line2 = "YOU?"
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "We'll use this to show you nearby events.",
            style = BurnerTypography.body,
            color = BurnerColors.White.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(40.dp))

        if (!showManualInput) {
            // Current location button
            Surface(
                onClick = onUseCurrentLocation,
                enabled = !isLoading,
                modifier = Modifier.width(220.dp).height(48.dp),
                shape = CircleShape,
                color = BurnerColors.White
            ) {
                Row(
                    modifier = Modifier.fillMaxSize(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(18.dp),
                            color = BurnerColors.Black,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(
                            imageVector = Icons.Filled.LocationOn,
                            contentDescription = null,
                            tint = BurnerColors.Black,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = locationName ?: "CURRENT LOCATION",
                        style = BurnerTypography.secondary.copy(fontWeight = FontWeight.Bold),
                        color = BurnerColors.Black
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Enter city button
            Surface(
                onClick = { showManualInput = true },
                modifier = Modifier.width(160.dp).height(48.dp),
                shape = CircleShape,
                color = Color.Transparent,
                border = androidx.compose.foundation.BorderStroke(1.dp, BurnerColors.White)
            ) {
                Row(
                    modifier = Modifier.fillMaxSize(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Filled.Search,
                        contentDescription = null,
                        tint = BurnerColors.White,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "ENTER CITY",
                        style = BurnerTypography.secondary.copy(fontWeight = FontWeight.Bold),
                        color = BurnerColors.White
                    )
                }
            }
        } else {
            // Manual entry mode
            OutlinedTextField(
                value = manualLocation,
                onValueChange = { manualLocation = it },
                placeholder = {
                    Text(
                        "Enter your city",
                        color = BurnerColors.TextSecondary
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = BurnerColors.White,
                    unfocusedBorderColor = BurnerColors.Border,
                    focusedTextColor = BurnerColors.White,
                    unfocusedTextColor = BurnerColors.White,
                    cursorColor = BurnerColors.White
                ),
                shape = RoundedCornerShape(12.dp),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                CapsuleButton(
                    text = "BACK",
                    isPrimary = false,
                    onClick = { showManualInput = false },
                    modifier = Modifier.weight(1f)
                )
                CapsuleButton(
                    text = "SET",
                    isPrimary = true,
                    onClick = {
                        onManualEntry(manualLocation.uppercase())
                        showManualInput = false
                    },
                    modifier = Modifier.weight(1f),
                    enabled = manualLocation.isNotBlank()
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))
    }
}

// MARK: - Genres Step
@Composable
private fun GenresStep(
    genres: List<String>,
    selectedGenres: Set<String>,
    onGenreToggle: (String) -> Unit,
    onContinue: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        TightHeaderText(
            line1 = "WHAT'S YOUR",
            line2 = "VIBE?"
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Get personalized event recommendations.",
            style = BurnerTypography.body,
            color = BurnerColors.White.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Genre pills in a flow layout
        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            genres.forEach { genre ->
                GenrePill(
                    name = genre,
                    isSelected = selectedGenres.contains(genre),
                    onClick = { onGenreToggle(genre) }
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Arrow button appears when genres selected
        AnimatedVisibility(
            visible = selectedGenres.isNotEmpty(),
            enter = scaleIn() + fadeIn(),
            exit = scaleOut() + fadeOut()
        ) {
            Surface(
                onClick = onContinue,
                modifier = Modifier.size(60.dp),
                shape = CircleShape,
                color = BurnerColors.White
            ) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                        contentDescription = "Continue",
                        tint = BurnerColors.Black,
                        modifier = Modifier.size(28.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.weight(1f))
    }
}

@Composable
private fun FlowRow(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    content: @Composable () -> Unit
) {
    // Use the actual FlowRow from compose
    androidx.compose.foundation.layout.FlowRow(
        modifier = modifier,
        horizontalArrangement = horizontalArrangement,
        verticalArrangement = verticalArrangement
    ) {
        content()
    }
}

@Composable
private fun GenrePill(
    name: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor = if (isSelected) BurnerColors.White else Color.Transparent
    val textColor = if (isSelected) BurnerColors.Black else BurnerColors.White
    val borderColor = if (isSelected) Color.Transparent else BurnerColors.White.copy(alpha = 0.3f)

    Surface(
        onClick = onClick,
        modifier = Modifier.padding(horizontal = 4.dp),
        shape = CircleShape,
        color = backgroundColor,
        border = if (!isSelected) androidx.compose.foundation.BorderStroke(1.5.dp, borderColor) else null
    ) {
        Text(
            text = name.lowercase(),
            style = BurnerTypography.body.copy(
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
            ),
            color = textColor,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 12.dp)
        )
    }
}

// MARK: - Notifications Step
@Composable
private fun NotificationsStep(
    onEnable: () -> Unit,
    onSkip: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        TightHeaderText(
            line1 = "STAY IN",
            line2 = "THE LOOP"
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Get alerts for new events and updates on shows you're interested in.",
            style = BurnerTypography.body,
            color = BurnerColors.White.copy(alpha = 0.7f),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 20.dp)
        )

        Spacer(modifier = Modifier.height(40.dp))

        CapsuleButton(
            text = "I'M IN",
            isPrimary = true,
            onClick = onEnable,
            modifier = Modifier.width(140.dp)
        )

        Spacer(modifier = Modifier.weight(1f))
    }
}

// MARK: - Complete Step
@Composable
private fun CompleteStep() {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Checkmark circle
        Box(
            modifier = Modifier
                .size(100.dp)
                .background(
                    color = BurnerColors.White.copy(alpha = 0.1f),
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                tint = BurnerColors.White,
                modifier = Modifier.size(50.dp)
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        TightHeaderText(
            line1 = "YOU'RE",
            line2 = "IN!"
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Let's explore what's happening near you.",
            style = BurnerTypography.body,
            color = BurnerColors.White.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )
    }
}
