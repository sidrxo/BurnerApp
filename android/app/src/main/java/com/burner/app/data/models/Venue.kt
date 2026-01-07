package com.burner.app.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Venue model matching iOS Venue struct
 * Updated for Supabase
 */
@Serializable
data class Venue(
    val id: String? = null,
    val name: String = "",
    val address: String = "",
    val city: String = "",
    val capacity: Int = 0,
    @SerialName("image_url")
    val imageUrl: String = "",
    val latitude: Double? = null,
    val longitude: Double? = null,
    @SerialName("event_count")
    val eventCount: Int = 0
) {
    companion object {
        fun empty() = Venue()
    }
}
