package com.burner.app.navigation

/**
 * Navigation routes for the Burner app
 * Matching iOS NavigationCoordinator destinations
 */
sealed class Routes(val route: String) {
    // Onboarding
    object Onboarding : Routes("onboarding")
    object OnboardingWelcome : Routes("onboarding/welcome")
    object OnboardingLocation : Routes("onboarding/location")
    object OnboardingGenres : Routes("onboarding/genres")
    object OnboardingNotifications : Routes("onboarding/notifications")
    object OnboardingComplete : Routes("onboarding/complete")

    // Auth
    object SignIn : Routes("auth/signin")
    object SignUp : Routes("auth/signup")

    // Main tabs
    object Main : Routes("main")
    object Explore : Routes("explore")
    object Search : Routes("search")
    object Bookmarks : Routes("bookmarks")
    object Tickets : Routes("tickets")

    // Event related
    object EventDetail : Routes("event/{eventId}") {
        fun createRoute(eventId: String) = "event/$eventId"
    }

    // Ticket related
    object TicketDetail : Routes("ticket/{ticketId}") {
        fun createRoute(ticketId: String) = "ticket/$ticketId"
    }

    object TicketPurchase : Routes("purchase/{eventId}") {
        fun createRoute(eventId: String) = "purchase/$eventId"
    }

    // Settings
    object Settings : Routes("settings")
    object AccountDetails : Routes("settings/account")
    object PaymentSettings : Routes("settings/payment")
    object NotificationSettings : Routes("settings/notifications")
    object Support : Routes("settings/support")
    object FAQ : Routes("settings/faq")
    object TermsOfService : Routes("settings/terms")
    object PrivacyPolicy : Routes("settings/privacy")

    // Scanner
    object Scanner : Routes("scanner")

    // Burner Mode (stub)
    object BurnerModeSetup : Routes("burner/setup")
    object BurnerModeLockScreen : Routes("burner/lock")

    companion object {
        const val EVENT_ID_KEY = "eventId"
        const val TICKET_ID_KEY = "ticketId"
    }
}

/**
 * Bottom navigation tabs
 */
enum class BottomNavTab(val route: String, val label: String) {
    EXPLORE("explore", "Explore"),
    SEARCH("search", "Search"),
    BOOKMARKS("bookmarks", "Saves"),
    TICKETS("tickets", "Tickets")
}
