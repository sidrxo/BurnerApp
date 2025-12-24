package com.burner.shared.utils

import kotlinx.datetime.*
import kotlin.time.Duration.Companion.days

/**
 * Date and time utility functions
 */
object DateUtils {

    /**
     * Format a date to a readable string
     */
    fun formatDate(instant: Instant, timeZone: TimeZone = TimeZone.currentSystemDefault()): String {
        val localDateTime = instant.toLocalDateTime(timeZone)
        return "${localDateTime.month.name.lowercase().replaceFirstChar { it.uppercase() }} ${localDateTime.dayOfMonth}, ${localDateTime.year}"
    }

    /**
     * Format time to a readable string (e.g., "7:00 PM")
     * Fixed for KMP (Removed String.format)
     */
    fun formatTime(instant: Instant, timeZone: TimeZone = TimeZone.currentSystemDefault()): String {
        val localDateTime = instant.toLocalDateTime(timeZone)
        val hour = localDateTime.hour
        val minute = localDateTime.minute

        val period = if (hour < 12) "AM" else "PM"
        val hour12 = when {
            hour == 0 -> 12
            hour > 12 -> hour - 12
            else -> hour
        }

        // Manual padding for minutes (e.g., 5 -> "05")
        val minuteStr = if (minute < 10) "0$minute" else "$minute"

        return "$hour12:$minuteStr $period"
    }

    /**
     * Format date and time together
     */
    fun formatDateTime(instant: Instant, timeZone: TimeZone = TimeZone.currentSystemDefault()): String {
        return "${formatDate(instant, timeZone)} at ${formatTime(instant, timeZone)}"
    }

    /**
     * Get relative time string (e.g., "2 days ago", "in 3 hours")
     */
    fun getRelativeTimeString(instant: Instant): String {
        val now = Clock.System.now()
        val duration = instant - now

        return when {
            duration.inWholeSeconds < 0 -> {
                // Past
                val absDuration = -duration.inWholeSeconds
                when {
                    absDuration < 60 -> "just now"
                    absDuration < 3600 -> "${absDuration / 60} minutes ago"
                    absDuration < 86400 -> "${absDuration / 3600} hours ago"
                    absDuration < 604800 -> "${absDuration / 86400} days ago"
                    else -> formatDate(instant)
                }
            }
            else -> {
                // Future
                val seconds = duration.inWholeSeconds
                when {
                    seconds < 60 -> "in a moment"
                    seconds < 3600 -> "in ${seconds / 60} minutes"
                    seconds < 86400 -> "in ${seconds / 3600} hours"
                    seconds < 604800 -> "in ${seconds / 86400} days"
                    else -> formatDate(instant)
                }
            }
        }
    }

    /**
     * Check if an instant is today
     */
    fun isToday(instant: Instant, timeZone: TimeZone = TimeZone.currentSystemDefault()): Boolean {
        val today = Clock.System.now().toLocalDateTime(timeZone).date
        val date = instant.toLocalDateTime(timeZone).date
        return date == today
    }

    /**
     * Check if an instant is this week
     */
    fun isThisWeek(instant: Instant, timeZone: TimeZone = TimeZone.currentSystemDefault()): Boolean {
        val now = Clock.System.now()
        val sevenDaysLater = now + 7.days
        return instant in now..sevenDaysLater
    }
}