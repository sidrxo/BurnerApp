package com.burner.shared.utils

import kotlin.math.*

/**
 * Calculate the distance between two geographic coordinates using the Haversine formula
 * @param lat1 Latitude of first point
 * @param lon1 Longitude of first point
 * @param lat2 Latitude of second point
 * @param lon2 Longitude of second point
 * @return Distance in kilometers
 */
fun haversineDistance(
    lat1: Double,
    lon1: Double,
    lat2: Double,
    lon2: Double
): Double {
    val earthRadiusKm = 6371.0

    val dLat = (lat2 - lat1).toRadians()
    val dLon = (lon2 - lon1).toRadians()

    val a = sin(dLat / 2).pow(2) +
            cos(lat1.toRadians()) * cos(lat2.toRadians()) *
            sin(dLon / 2).pow(2)

    val c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return earthRadiusKm * c
}

/**
 * Convert degrees to radians
 */
private fun Double.toRadians(): Double = this * PI / 180.0
