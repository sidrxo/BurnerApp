package com.burner.app.data.models

import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.GeoPoint
import com.google.firebase.firestore.PropertyName

/**
 * Venue model matching iOS Venue struct
 */
data class Venue(
    @DocumentId
    val id: String? = null,
    val name: String = "",
    val address: String = "",
    val city: String = "",
    val capacity: Int = 0,
    @PropertyName("imageUrl")
    val imageUrl: String = "",
    val coordinates: GeoPoint? = null,
    @PropertyName("eventCount")
    val eventCount: Int = 0
) {
    companion object {
        fun empty() = Venue()
    }
}
