package com.burner.app.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.burner.app.ui.screens.auth.SignInScreen
import com.burner.app.ui.screens.explore.EventDetailScreen
import com.burner.app.ui.screens.main.MainTabsScreen // Import the new screen
import com.burner.app.ui.screens.onboarding.OnboardingFlowScreen
import com.burner.app.ui.screens.settings.*
import com.burner.app.ui.screens.tickets.TicketDetailScreen
import com.burner.app.ui.screens.tickets.TicketPurchaseScreen
import com.burner.app.ui.theme.BurnerColors

@Composable
fun BurnerNavHost(
    navController: NavHostController = rememberNavController(),
    viewModel: NavigationViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    val startDestination = when {
        uiState.isLoading -> Routes.Main.route
        uiState.hasCompletedOnboarding == true -> Routes.Main.route
        else -> Routes.Onboarding.route
    }

    // Removed Scaffold from here. MainTabsScreen now handles the BottomBar.
    if (!uiState.isLoading) {
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = Modifier
                .fillMaxSize()
                .background(BurnerColors.Background),
            enterTransition = { fadeIn(animationSpec = tween(300)) },
            exitTransition = { fadeOut(animationSpec = tween(300)) }
        ) {
            // 1. Onboarding
            composable(Routes.Onboarding.route) {
                OnboardingFlowScreen(
                    onComplete = {
                        viewModel.completeOnboarding()
                        navController.navigate(Routes.Main.route) {
                            popUpTo(Routes.Onboarding.route) { inclusive = true }
                        }
                    }
                )
            }

            // 2. Auth
            composable(
                Routes.SignIn.route,
                enterTransition = { slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.Up) },
                exitTransition = { slideOutOfContainer(AnimatedContentTransitionScope.SlideDirection.Down) }
            ) {
                SignInScreen(
                    onDismiss = { navController.popBackStack() },
                    onSignInSuccess = { navController.popBackStack() }
                )
            }

            // 3. MAIN TABS (Holds Explore, Search, Bookmarks, Tickets in a Pager)
            composable(Routes.Main.route) {
                MainTabsScreen(
                    onEventClick = { eventId ->
                        navController.navigate(Routes.EventDetail.createRoute(eventId))
                    },
                    onSignInClick = {
                        navController.navigate(Routes.SignIn.route)
                    },
                    onSettingsClick = {
                        navController.navigate(Routes.Settings.route)
                    }
                )
            }

            // NOTE: We REMOVED the individual composable(Routes.Explore), composable(Routes.Search), etc.
            // because they are now inside MainTabsScreen.

            // 4. Detail Screens (These cover the tabs when navigated to)

            // Event Detail
            composable(
                route = Routes.EventDetail.route,
                arguments = listOf(navArgument(Routes.EVENT_ID_KEY) { type = NavType.StringType }),
                enterTransition = { slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.Left) },
                exitTransition = { slideOutOfContainer(AnimatedContentTransitionScope.SlideDirection.Right) }
            ) { backStackEntry ->
                val eventId = backStackEntry.arguments?.getString(Routes.EVENT_ID_KEY) ?: ""
                EventDetailScreen(
                    eventId = eventId,
                    onBackClick = { navController.popBackStack() },
                    onGetTicketsClick = { id ->
                        navController.navigate(Routes.TicketPurchase.createRoute(id))
                    }
                )
            }

            // Ticket Detail
            composable(
                route = Routes.TicketDetail.route,
                arguments = listOf(navArgument(Routes.TICKET_ID_KEY) { type = NavType.StringType })
            ) { backStackEntry ->
                val ticketId = backStackEntry.arguments?.getString(Routes.TICKET_ID_KEY) ?: ""
                TicketDetailScreen(
                    ticketId = ticketId,
                    onBackClick = { navController.popBackStack() }
                )
            }

            // Ticket Purchase
            composable(
                route = Routes.TicketPurchase.route,
                arguments = listOf(navArgument(Routes.EVENT_ID_KEY) { type = NavType.StringType }),
                enterTransition = { slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.Up) },
                exitTransition = { slideOutOfContainer(AnimatedContentTransitionScope.SlideDirection.Down) }
            ) { backStackEntry ->
                val eventId = backStackEntry.arguments?.getString(Routes.EVENT_ID_KEY) ?: ""
                TicketPurchaseScreen(
                    eventId = eventId,
                    onDismiss = { navController.popBackStack() },
                    onPurchaseComplete = {
                        navController.popBackStack()
                        // Navigate back to Main (Tickets tab is managed inside MainTabsScreen logic if needed)
                        navController.navigate(Routes.Main.route)
                    }
                )
            }

            // Settings
            composable(
                Routes.Settings.route,
                enterTransition = { slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.Left) }
            ) {
                SettingsScreen(
                    onBackClick = { navController.popBackStack() },
                    onAccountClick = { navController.navigate(Routes.AccountDetails.route) },
                    onPaymentClick = { navController.navigate(Routes.PaymentSettings.route) },
                    onNotificationsClick = { navController.navigate(Routes.NotificationSettings.route) },
                    onScannerClick = { navController.navigate(Routes.Scanner.route) },
                    onSupportClick = { navController.navigate(Routes.Support.route) },
                    onFAQClick = { navController.navigate(Routes.FAQ.route) },
                    onTermsClick = { navController.navigate(Routes.TermsOfService.route) },
                    onPrivacyClick = { navController.navigate(Routes.PrivacyPolicy.route) },
                    onSignInClick = { navController.navigate(Routes.SignIn.route) }
                )
            }

            // ... (Keep all your Settings sub-screens here: Account, Payment, Scanner, etc.) ...
            composable(Routes.AccountDetails.route) {
                AccountDetailsScreen(
                    onBackClick = { navController.popBackStack() },
                    onSignOut = {
                        navController.navigate(Routes.Onboarding.route) {
                            popUpTo(0) { inclusive = true }
                                }
                            }
                        )
                    }

                    composable(Routes.PaymentSettings.route) {
                        PaymentSettingsScreen(onBackClick = { navController.popBackStack() })
                    }

                    composable(Routes.NotificationSettings.route) {
                        NotificationSettingsScreen(onBackClick = { navController.popBackStack() })
                    }

                    composable(Routes.Support.route) {
                        SupportScreen(onBackClick = { navController.popBackStack() })
                    }

                    composable(Routes.FAQ.route) {
                        FAQScreen(onBackClick = { navController.popBackStack() })
                    }

                    composable(Routes.TermsOfService.route) {
                        TermsOfServiceScreen(onBackClick = { navController.popBackStack() })
                    }

                    composable(Routes.PrivacyPolicy.route) {
                        PrivacyPolicyScreen(onBackClick = { navController.popBackStack() })
                    }

                    // Scanner
                    composable(
                        Routes.Scanner.route,
                        enterTransition = {
                            slideIntoContainer(
                                AnimatedContentTransitionScope.SlideDirection.Left,
                                animationSpec = tween(300)
                            )
                        },
                        exitTransition = {
                            slideOutOfContainer(
                                AnimatedContentTransitionScope.SlideDirection.Right,
                                animationSpec = tween(300)
                            )
                        }
                    ) {
                    }
                }
            }
        }
