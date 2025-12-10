package com.burner.app.ui.screens.onboarding

import android.Manifest
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
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
    val notificationPermissionState = rememberPermissionState(Manifest.permission.POST_NOTIFICATIONS)

    // Auto-advance from complete step
    LaunchedEffect(uiState.currentStep) {
        if (uiState.currentStep == OnboardingStep.COMPLETE) {
            delay(1500)
            onComplete()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        AnimatedContent(
            targetState = uiState.currentStep,
            transitionSpec = {
                fadeIn() + slideInHorizontally { it } togetherWith
                        fadeOut() + slideOutHorizontally { -it }
            },
            label = "onboarding_transition"
        ) { step ->
            when (step) {
                OnboardingStep.WELCOME -> WelcomeStep(
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
                        notificationPermissionState.launchPermissionRequest()
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

@Composable
private fun WelcomeStep(
    onSignIn: () -> Unit,
    onExplore: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(BurnerDimensions.paddingScreen),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Spacer(modifier = Modifier.weight(1f))

        Text(
            text = "MEET ME IN\nTHE MOMENT",
            style = BurnerTypography.hero,
            color = BurnerColors.White,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))

        Text(
            text = "Discover events. Go offline. Be present.",
            style = BurnerTypography.body,
            color = BurnerColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.weight(1f))

        PrimaryButton(
            text = "SIGN UP / SIGN IN",
            onClick = onSignIn
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

        SecondaryButton(
            text = "EXPLORE",
            onClick = onExplore
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))
    }
}

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
            .padding(BurnerDimensions.paddingScreen),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.weight(0.3f))

        Text(
            text = "WHERE ARE YOU?",
            style = BurnerTypography.hero,
            color = BurnerColors.White,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

        Text(
            text = "Find events near you",
            style = BurnerTypography.body,
            color = BurnerColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

        if (locationName != null) {
            Text(
                text = locationName,
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingLg))
        }

        if (!showManualInput) {
            IconTextButton(
                text = "USE CURRENT LOCATION",
                icon = Icons.Filled.LocationOn,
                onClick = onUseCurrentLocation,
                enabled = !isLoading
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            TextButton(
                text = "Enter manually",
                onClick = { showManualInput = true }
            )
        } else {
            BurnerTextField(
                value = manualLocation,
                onValueChange = { manualLocation = it },
                placeholder = "Enter your city",
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingMd)
            ) {
                SecondaryButton(
                    text = "BACK",
                    onClick = { showManualInput = false },
                    modifier = Modifier.weight(1f)
                )
                PrimaryButton(
                    text = "SET",
                    onClick = {
                        onManualEntry(manualLocation)
                        showManualInput = false
                    },
                    modifier = Modifier.weight(1f),
                    enabled = manualLocation.isNotBlank()
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        PrimaryButton(
            text = "CONTINUE",
            onClick = onContinue,
            enabled = locationName != null || !showManualInput
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))
    }
}

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
            .padding(BurnerDimensions.paddingScreen),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.weight(0.2f))

        Text(
            text = "WHAT'S YOUR VIBE?",
            style = BurnerTypography.hero,
            color = BurnerColors.White,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

        Text(
            text = "Select your favourite genres",
            style = BurnerTypography.body,
            color = BurnerColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

        // Genre chips in a flow layout
        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalArrangement = Arrangement.spacedBy(BurnerDimensions.spacingSm)
        ) {
            genres.forEach { genre ->
                GenreChip(
                    name = genre,
                    selected = selectedGenres.contains(genre),
                    onClick = { onGenreToggle(genre) },
                    modifier = Modifier.padding(horizontal = BurnerDimensions.spacingXs)
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        AnimatedVisibility(
            visible = selectedGenres.isNotEmpty(),
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it }
        ) {
            PrimaryButton(
                text = "I'M IN",
                onClick = onContinue
            )
        }

        if (selectedGenres.isEmpty()) {
            TextButton(
                text = "Skip for now",
                onClick = onContinue
            )
        }

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))
    }
}

@Composable
private fun FlowRow(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    content: @Composable () -> Unit
) {
    // Simple flow layout implementation
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = verticalArrangement
    ) {
        Row(
            horizontalArrangement = horizontalArrangement,
            modifier = Modifier.fillMaxWidth()
        ) {
            content()
        }
    }
}

@Composable
private fun NotificationsStep(
    onEnable: () -> Unit,
    onSkip: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(BurnerDimensions.paddingScreen),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Spacer(modifier = Modifier.weight(0.3f))

        Icon(
            imageVector = Icons.Filled.Notifications,
            contentDescription = null,
            tint = BurnerColors.White,
            modifier = Modifier.size(64.dp)
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

        Text(
            text = "STAY IN THE LOOP",
            style = BurnerTypography.hero,
            color = BurnerColors.White,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

        Text(
            text = "Get notified about events you'll love",
            style = BurnerTypography.body,
            color = BurnerColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.weight(1f))

        PrimaryButton(
            text = "ENABLE NOTIFICATIONS",
            onClick = onEnable
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

        TextButton(
            text = "Maybe later",
            onClick = onSkip
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))
    }
}

@Composable
private fun CompleteStep() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(BurnerDimensions.paddingScreen),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Filled.Check,
            contentDescription = null,
            tint = BurnerColors.Success,
            modifier = Modifier.size(80.dp)
        )

        Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

        Text(
            text = "YOU'RE IN!",
            style = BurnerTypography.hero,
            color = BurnerColors.White,
            textAlign = TextAlign.Center
        )
    }
}
