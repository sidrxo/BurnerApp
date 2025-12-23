package com.burner.shared.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Venue model
 * Based on iOS Venue struct
 */
@Serializable
data class Venue(
    val id: String? = null,
    val name: String = "",
    val address: String = "",
    val city: String = "",
    val capacity: Int = 0,
    @SerialName("image_url")
    val imageUrl: String? = null,
    @SerialName("contact_email")
    val contactEmail: String = "",
    val website: String = "",
    val admins: List<String> = emptyList(),
    @SerialName("sub_admins")
    val subAdmins: List<String> = emptyList(),
    val active: Boolean = true,
    @SerialName("event_count")
    val eventCount: Int = 0,
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("created_by")
    val createdBy: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null,
    val coordinates: Coordinate? = null
) {
    companion object {
        fun empty() = Venue()
    }
}
