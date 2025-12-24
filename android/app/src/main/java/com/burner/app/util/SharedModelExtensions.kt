package com.burner.app.util

import com.burner.shared.models.Event
import com.burner.shared.models.Ticket
import com.burner.shared.models.Bookmark
import com.burner.shared.models.Venue
import kotlinx.datetime.Instant
import java.util.Date

/**
 * Android-specific extensions for shared KMP models
 * Provides compatibility with Android-specific code that uses java.util.Date
 */

// Event extensions
val Event.latitude: Double?
    get() = coordinates?.latitude

val Event.longitude: Double?
    get() = coordinates?.longitude

val Event.startDate: Date?
    get() = startInstant?.let { Date(it.toEpochMilliseconds()) }

val Event.endDate: Date?
    get() = endInstant?.let { Date(it.toEpochMilliseconds()) }

// Ticket extensions
val Ticket.startDate: Date?
    get() = startInstant?.let { Date(it.toEpochMilliseconds()) }

val Ticket.purchaseDateValue: Date?
    get() = purchaseInstant?.let { Date(it.toEpochMilliseconds()) }

// Bookmark extensions
val Bookmark.startDate: Date?
    get() = startInstant?.let { Date(it.toEpochMilliseconds()) }

val Bookmark.bookmarkedDate: Date?
    get() = bookmarkedInstant?.let { Date(it.toEpochMilliseconds()) }

// Venue extensions
val Venue.latitude: Double?
    get() = coordinates?.latitude

val Venue.longitude: Double?
    get() = coordinates?.longitude
