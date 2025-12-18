package com.burner.app.ui.screens.onboarding

import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
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

@Composable
fun OnboardingFlowScreen(onComplete: () -> Unit) {
    val viewModel: OnboardingViewModel = hiltViewModel()
    val uiState by viewModel.uiState.collectAsState()

    // When the final step is reached, trigger completion after a delay
    LaunchedEffect(uiState.currentStep) {
        if (uiState.currentStep == OnboardingStep.COMPLETE) {
            delay(1000) // Match iOS 1.0s delay
            viewModel.savePreferences()
            onComplete()
        }
    }

    Scaffold(
        topBar = {
            OnboardingTopBar(
                currentStep = uiState.currentStep,
                onBack = { viewModel.previousStep() },
                onSkip = { viewModel.skipStep() }
            )
        },
        containerColor = BurnerColors.Background
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            OnboardingAnimatedContent(uiState = uiState, viewModel = viewModel)
        }
    }
}

@OptIn(ExperimentalAnimationApi::class)
@Composable
private fun OnboardingAnimatedContent(uiState: OnboardingUiState, viewModel: OnboardingViewModel) {
    val currentStep = uiState.currentStep

    // Animate between steps
    AnimatedContent(targetState = currentStep, transitionSpec = {
        if (targetState.ordinal > initialState.ordinal) {
            (slideInHorizontally { width -> width } + fadeIn()).togetherWith(slideOutHorizontally { width -> -width } + fadeOut())
        } else {
            (slideInHorizontally { width -> -width } + fadeIn()).togetherWith(slideOutHorizontally { width -> width } + fadeOut())
        }.using(
            SizeTransform(clip = false)
        )
    }) { step ->
        when (step) {
            OnboardingStep.WELCOME -> AuthWelcomeStep(
                imageUrls = uiState.eventImageUrls,
                onSignIn = { viewModel.nextStep() },
                onExplore = { viewModel.skipToComplete() }
            )
            OnboardingStep.LOCATION -> LocationStep(
                locationName = uiState.locationName,
                isLoading = uiState.isLoadingLocation,
                onUseCurrentLocation = { viewModel.detectCurrentLocation() },
                onManualEntry = { viewModel.setLocationManually(it) }
            )
            OnboardingStep.GENRES -> GenresStep(
                genres = uiState.availableGenres,
                selectedGenres = uiState.selectedGenres,
                onGenreToggle = { viewModel.toggleGenre(it) },
                onContinue = { viewModel.nextStep() }
            )
            OnboardingStep.NOTIFICATIONS -> NotificationsStep(
                onEnable = {
                    viewModel.setNotificationsEnabled(true)
                    viewModel.nextStep()
                },
                onSkip = { viewModel.nextStep() }
            )
            OnboardingStep.COMPLETE -> CompleteStep()
        }
    }
}

@Composable
private fun OnboardingTopBar(
    currentStep: OnboardingStep,
    onBack: () -> Unit,
    onSkip: () -> Unit
) {
    val showProgress = currentStep in listOf(OnboardingStep.LOCATION, OnboardingStep.GENRES, OnboardingStep.NOTIFICATIONS)
    val showBackButton = currentStep.ordinal > OnboardingStep.WELCOME.ordinal && currentStep != OnboardingStep.COMPLETE
    val showSkipButton = showProgress

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center
    ) {
        if (showBackButton) {
            IconButton(onClick = onBack, modifier = Modifier.align(Alignment.CenterStart)) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = BurnerColors.White)
            }
        }

        if (showProgress) {
            Row(
                modifier = Modifier.align(Alignment.Center),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val totalFlowSteps = 3 // Location, Genres, Notifications
                val progress = when(currentStep) {
                    OnboardingStep.LOCATION -> 1
                    OnboardingStep.GENRES -> 2
                    OnboardingStep.NOTIFICATIONS -> 3
                    else -> 0
                }
                for (i in 1..totalFlowSteps) {
                    Box(
                        modifier = Modifier
                            .height(4.dp)
                            .width(30.dp)
                            .background(
                                color = if (i <= progress) BurnerColors.White else BurnerColors.Border,
                                shape = CircleShape
                            )
                    )
                }
            }
        }

        if (showSkipButton) {
            TextButton(onClick = onSkip, modifier = Modifier.align(Alignment.CenterEnd)) {
                Text("SKIP", style = BurnerTypography.secondary, color = BurnerColors.TextDimmed)
            }
        }
    }
}

@Composable
private fun AuthWelcomeStep(
    imageUrls: List<String>,
    onSignIn: () -> Unit,
    onExplore: () -> Unit
) {
    var showSignIn by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        // Rotated mosaic background
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .offset(y = (-50).dp)
                .graphicsLayer(rotationZ = -6f),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (imageUrls.isNotEmpty()) {
                MosaicRow(imageUrls = imageUrls.take(4))
                MosaicRow(imageUrls = imageUrls.drop(4).take(4))
                MosaicRow(imageUrls = imageUrls.drop(8).take(4))
            } else {
                // Placeholder if no images
                Box(modifier = Modifier.fillMaxSize(0.8f).background(BurnerColors.CardBackground))
            }
        }

        // Content on top
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Bottom
        ) {
            TightHeaderText(
                line1 = "JOIN THE",
                line2 = "MOVEMENT"
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Sign Up/In Button
            CapsuleButton(
                text = "SIGN UP/IN",
                isPrimary = true,
                onClick = { showSignIn = true },
                modifier = Modifier.width(200.dp)
            )

            Spacer(modifier = Modifier.height(14.dp))

            // Explore Button
            CapsuleButton(
                text = "EXPLORE",
                isPrimary = false,
                onClick = onExplore,
                modifier = Modifier.width(160.dp)
            )

            Spacer(modifier = Modifier.height(80.dp))
        }

        // Bottom gradient
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.4f)
                .align(Alignment.BottomCenter)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, BurnerColors.Background)
                    )
                )
        )

        // Sign In Sheet
        if (showSignIn) {
            SignInScreen(
                onDismiss = { showSignIn = false },
                onSignInSuccess = {
                    showSignIn = false
                    onSignIn()
                }
            )
        }
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
        border = if (!isPrimary) BorderStroke(1.dp, borderColor) else null
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

@Composable
private fun LocationStep(
    locationName: String?,
    isLoading: Boolean,
    onUseCurrentLocation: () -> Unit,
    onManualEntry: (String) -> Unit
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
                border = BorderStroke(1.dp, BurnerColors.White)
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

@OptIn(ExperimentalLayoutApi::class)
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
        border = if (!isSelected) BorderStroke(1.5.dp, borderColor) else null
    ) {
        Text(
            text = name.lowercase(),
            style = BurnerTypography.body.copy(
                fontFamily = FontFamily.Monospace
            ),
            color = textColor,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 12.dp)
        )
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
