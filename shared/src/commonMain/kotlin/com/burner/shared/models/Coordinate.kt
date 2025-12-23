package com.burner.shared.models

import kotlinx.serialization.Serializable

/**
 * Coordinate model for geographic locations
 * Based on iOS Coordinate struct
 */
@Serializable
data class Coordinate(
    val latitude: Double,
    val longitude: Double
)
