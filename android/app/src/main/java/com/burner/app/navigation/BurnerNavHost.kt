package com.burner.app.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.burner.app.ui.components.BurnerBottomNavBar
import com.burner.app.ui.screens.auth.SignInScreen
import com.burner.app.ui.screens.bookmarks.BookmarksScreen
import com.burner.app.ui.screens.explore.EventDetailScreen
import com.burner.app.ui.screens.explore.ExploreScreen
import com.burner.app.ui.screens.onboarding.OnboardingFlowScreen
import com.burner.app.ui.screens.search.SearchScreen
import com.burner.app.ui.screens.settings.*
import com.burner.app.ui.screens.tickets.TicketDetailScreen
import com.burner.app.ui.screens.tickets.TicketPurchaseScreen
import com.burner.app.ui.screens.tickets.TicketsScreen
import com.burner.app.ui.theme.BurnerColors

@Composable
fun BurnerNavHost(
    navController: NavHostController = rememberNavController(),
    viewModel: NavigationViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    // Determine if we should show bottom nav
    val showBottomNav = currentRoute in listOf(
        Routes.Explore.route,
        Routes.Search.route,
        Routes.Bookmarks.route,
        Routes.Tickets.route
    )

    // Determine start destination based on onboarding completion
    val startDestination = if (uiState.hasCompletedOnboarding) {
        Routes.Main.route
    } else {
        Routes.Onboarding.route
    }

    Scaffold(
        containerColor = BurnerColors.Background,
        bottomBar = {
            if (showBottomNav) {
                BurnerBottomNavBar(
                    currentRoute = currentRoute ?: "",
                    onTabSelected = { tab ->
                        if (currentRoute != tab.route) {
                            navController.navigate(tab.route) {
                                popUpTo(Routes.Main.route) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    }
                )
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            NavHost(
                navController = navController,
                startDestination = startDestination,
                enterTransition = {
                    fadeIn(animationSpec = tween(300))
                },
                exitTransition = {
                    fadeOut(animationSpec = tween(300))
                }
            ) {
                // Onboarding
                composable(Routes.Onboarding.route) {
                    OnboardingFlowScreen(
                        onComplete = {
                            viewModel.completeOnboarding()
                            navController.navigate(Routes.Main.route) {
                                popUpTo(Routes.Onboarding.route) { inclusive = true }
                            }
                        },
                        onSignIn = {
                            navController.navigate(Routes.SignIn.route)
                        }
                    )
                }

                // Auth
                composable(
                    Routes.SignIn.route,
                    enterTransition = {
                        slideIntoContainer(
                            AnimatedContentTransitionScope.SlideDirection.Up,
                            animationSpec = tween(300)
                        )
                    },
                    exitTransition = {
                        slideOutOfContainer(
                            AnimatedContentTransitionScope.SlideDirection.Down,
                            animationSpec = tween(300)
                        )
                    }
                ) {
                    SignInScreen(
                        onDismiss = { navController.popBackStack() },
                        onSignInSuccess = {
                            navController.popBackStack()
                        }
                    )
                }

                // Main tabs container
                composable(Routes.Main.route) {
                    // Redirect to explore
                    navController.navigate(Routes.Explore.route) {
                        popUpTo(Routes.Main.route) { inclusive = true }
                    }
                }

                // Explore
                composable(Routes.Explore.route) {
                    ExploreScreen(
                        onEventClick = { eventId ->
                            navController.navigate(Routes.EventDetail.createRoute(eventId))
                        },
                        onSettingsClick = {
                            navController.navigate(Routes.Settings.route)
                        }
                    )
                }

                // Search
                composable(Routes.Search.route) {
                    SearchScreen(
                        onEventClick = { eventId ->
                            navController.navigate(Routes.EventDetail.createRoute(eventId))
                        }
                    )
                }

                // Bookmarks
                composable(Routes.Bookmarks.route) {
                    BookmarksScreen(
                        onEventClick = { eventId ->
                            navController.navigate(Routes.EventDetail.createRoute(eventId))
                        },
                        onSignInClick = {
                            navController.navigate(Routes.SignIn.route)
                        }
                    )
                }

                // Tickets
                composable(Routes.Tickets.route) {
                    TicketsScreen(
                        onTicketClick = { ticketId ->
                            navController.navigate(Routes.TicketDetail.createRoute(ticketId))
                        },
                        onSignInClick = {
                            navController.navigate(Routes.SignIn.route)
                        }
                    )
                }

                // Event Detail
                composable(
                    route = Routes.EventDetail.route,
                    arguments = listOf(
                        navArgument(Routes.EVENT_ID_KEY) { type = NavType.StringType }
                    ),
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
                ) { backStackEntry ->
                    val eventId = backStackEntry.arguments?.getString(Routes.EVENT_ID_KEY) ?: ""
                    EventDetailScreen(
                        eventId = eventId,
                        onBackClick = { navController.popBackStack() },
                        onGetTicketsClick = { eventId ->
                            navController.navigate(Routes.TicketPurchase.createRoute(eventId))
                        }
                    )
                }

                // Ticket Detail
                composable(
                    route = Routes.TicketDetail.route,
                    arguments = listOf(
                        navArgument(Routes.TICKET_ID_KEY) { type = NavType.StringType }
                    )
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
                    arguments = listOf(
                        navArgument(Routes.EVENT_ID_KEY) { type = NavType.StringType }
                    ),
                    enterTransition = {
                        slideIntoContainer(
                            AnimatedContentTransitionScope.SlideDirection.Up,
                            animationSpec = tween(300)
                        )
                    },
                    exitTransition = {
                        slideOutOfContainer(
                            AnimatedContentTransitionScope.SlideDirection.Down,
                            animationSpec = tween(300)
                        )
                    }
                ) { backStackEntry ->
                    val eventId = backStackEntry.arguments?.getString(Routes.EVENT_ID_KEY) ?: ""
                    TicketPurchaseScreen(
                        eventId = eventId,
                        onDismiss = { navController.popBackStack() },
                        onPurchaseComplete = {
                            navController.popBackStack()
                            navController.navigate(Routes.Tickets.route) {
                                popUpTo(Routes.Explore.route)
                            }
                        }
                    )
                }

                // Settings
                composable(
                    Routes.Settings.route,
                    enterTransition = {
                        slideIntoContainer(
                            AnimatedContentTransitionScope.SlideDirection.Left,
                            animationSpec = tween(300)
                        )
                    }
                ) {
                    SettingsScreen(
                        onBackClick = { navController.popBackStack() },
                        onAccountClick = { navController.navigate(Routes.AccountDetails.route) },
                        onPaymentClick = { navController.navigate(Routes.PaymentSettings.route) },
                        onNotificationsClick = { navController.navigate(Routes.NotificationSettings.route) },
                        onSupportClick = { navController.navigate(Routes.Support.route) },
                        onFAQClick = { navController.navigate(Routes.FAQ.route) },
                        onTermsClick = { navController.navigate(Routes.TermsOfService.route) },
                        onPrivacyClick = { navController.navigate(Routes.PrivacyPolicy.route) },
                        onSignOut = {
                            navController.navigate(Routes.Onboarding.route) {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    )
                }

                // Settings sub-screens
                composable(Routes.AccountDetails.route) {
                    AccountDetailsScreen(onBackClick = { navController.popBackStack() })
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
            }
        }
    }
}
