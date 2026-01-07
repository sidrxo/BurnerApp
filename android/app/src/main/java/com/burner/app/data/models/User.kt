package com.burner.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * User profile model for Supabase
 */
@Serializable
data class User(
    val id: String? = null,
    val email: String = "",
    @SerialName("display_name")
    val displayName: String? = null,
    val role: String = UserRole.USER,
    val provider: String = "",
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("last_login_at")
    val lastLoginAt: String? = null,
    val preferences: UserPreferences? = null
)

object UserRole {
    const val USER = "user"
    const val SCANNER = "scanner"
    const val VENUE_ADMIN = "venueAdmin"
    const val SUB_ADMIN = "subAdmin"
    const val SITE_ADMIN = "siteAdmin"
}

/**
 * User preferences stored in Supabase
 */
@Serializable
data class UserPreferences(
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

/**
 * Local preferences stored in DataStore
 */
data class LocalPreferences(
    val selectedGenres: List<String> = emptyList(),
    val locationName: String? = null,
    val locationLat: Double? = null,
    val locationLon: Double? = null,
    val hasEnabledNotifications: Boolean = false,
    val hasCompletedOnboarding: Boolean = false,
    val hasSeenWelcome: Boolean = false
)
