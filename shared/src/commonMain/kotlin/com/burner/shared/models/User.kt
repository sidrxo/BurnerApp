package com.burner.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * User profile model
 * Based on iOS UserProfile struct
 */
@Serializable
data class User(
    val id: String? = null,
    val email: String = "",
    @SerialName("display_name")
    val displayName: String? = null,
    val role: String = UserRole.USER,
    val provider: String = "",
    @SerialName("venue_permissions")
    val venuePermissions: List<String> = emptyList(),
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("last_login_at")
    val lastLoginAt: String? = null,
    @SerialName("phone_number")
    val phoneNumber: String? = null,
    @SerialName("stripe_customer_id")
    val stripeCustomerId: String? = null,
    @SerialName("profile_image_url")
    val profileImageUrl: String? = null,
    val preferences: UserPreferences? = null
)

/**
 * User role constants
 */
object UserRole {
    const val USER = "user"
    const val SCANNER = "scanner"
    const val VENUE_ADMIN = "venueAdmin"
    const val SUB_ADMIN = "subAdmin"
    const val SITE_ADMIN = "siteAdmin"
}

/**
 * User preferences stored in database
 */
@Serializable
data class UserPreferences(
    val notifications: Boolean = true,
    @SerialName("email_marketing")
    val emailMarketing: Boolean = false,
    @SerialName("push_notifications")
    val pushNotifications: Boolean = true,
    @SerialName("selected_genres")
    val selectedGenres: List<String> = emptyList(),
    @SerialName("location_name")
    val locationName: String? = null,
    @SerialName("location_lat")
    val locationLat: Double? = null,
    @SerialName("location_lon")
    val locationLon: Double? = null,
    @SerialName("has_enabled_notifications")
    val hasEnabledNotifications: Boolean = false,
    @SerialName("has_completed_onboarding")
    val hasCompletedOnboarding: Boolean = false
)
