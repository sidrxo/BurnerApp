package com.burner.app.data.repository

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import com.burner.app.data.models.LocalPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PreferencesRepository @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    companion object {
        private val SELECTED_GENRES = stringSetPreferencesKey("selected_genres")
        private val LOCATION_NAME = stringPreferencesKey("location_name")
        private val LOCATION_LAT = doublePreferencesKey("location_lat")
        private val LOCATION_LON = doublePreferencesKey("location_lon")
        private val HAS_ENABLED_NOTIFICATIONS = booleanPreferencesKey("has_enabled_notifications")
        private val HAS_COMPLETED_ONBOARDING = booleanPreferencesKey("has_completed_onboarding")
        private val HAS_SEEN_WELCOME = booleanPreferencesKey("has_seen_welcome")
    }

    val localPreferences: Flow<LocalPreferences> = dataStore.data
        .catch { exception ->
            emit(emptyPreferences())
        }
        .map { preferences ->
            LocalPreferences(
                selectedGenres = preferences[SELECTED_GENRES]?.toList() ?: emptyList(),
                locationName = preferences[LOCATION_NAME],
                locationLat = preferences[LOCATION_LAT],
                locationLon = preferences[LOCATION_LON],
                hasEnabledNotifications = preferences[HAS_ENABLED_NOTIFICATIONS] ?: false,
                hasCompletedOnboarding = preferences[HAS_COMPLETED_ONBOARDING] ?: false,
                hasSeenWelcome = preferences[HAS_SEEN_WELCOME] ?: false
            )
        }

    suspend fun setSelectedGenres(genres: List<String>) {
        dataStore.edit { preferences ->
            preferences[SELECTED_GENRES] = genres.toSet()
        }
    }

    suspend fun setLocation(name: String?, lat: Double?, lon: Double?) {
        dataStore.edit { preferences ->
            if (name != null) {
                preferences[LOCATION_NAME] = name
            } else {
                preferences.remove(LOCATION_NAME)
            }
            if (lat != null) {
                preferences[LOCATION_LAT] = lat
            } else {
                preferences.remove(LOCATION_LAT)
            }
            if (lon != null) {
                preferences[LOCATION_LON] = lon
            } else {
                preferences.remove(LOCATION_LON)
            }
        }
    }

    suspend fun setNotificationsEnabled(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[HAS_ENABLED_NOTIFICATIONS] = enabled
        }
    }

    suspend fun setOnboardingCompleted(completed: Boolean) {
        dataStore.edit { preferences ->
            preferences[HAS_COMPLETED_ONBOARDING] = completed
        }
    }

    suspend fun setHasSeenWelcome(seen: Boolean) {
        dataStore.edit { preferences ->
            preferences[HAS_SEEN_WELCOME] = seen
        }
    }

    suspend fun clearAll() {
        dataStore.edit { preferences ->
            preferences.clear()
        }
    }
}
