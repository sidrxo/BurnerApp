package com.burner.app.data.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.PropertyName

/**
 * User profile model
 */
data class User(
    @DocumentId
    val uid: String? = null,
    val email: String = "",
    @PropertyName("displayName")
    val displayName: String? = null,
    val role: String = UserRole.USER,
    val provider: String = "",
    @PropertyName("createdAt")
    val createdAt: Timestamp? = null,
    @PropertyName("lastLoginAt")
    val lastLoginAt: Timestamp? = null,
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
 * User preferences stored in Firestore
 */
data class UserPreferences(
    @PropertyName("selectedGenres")
    val selectedGenres: List<String> = emptyList(),
    @PropertyName("locationName")
    val locationName: String? = null,
    @PropertyName("locationLat")
    val locationLat: Double? = null,
    @PropertyName("locationLon")
    val locationLon: Double? = null,
    @PropertyName("hasEnabledNotifications")
    val hasEnabledNotifications: Boolean = false,
    @PropertyName("hasCompletedOnboarding")
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
