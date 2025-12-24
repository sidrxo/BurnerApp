package com.burner.shared.utils

/**
 * Price formatting utilities
 */
object PriceUtils {

    /**
     * Format a price to a currency string
     * @param price Price value
     * @param currencySymbol Currency symbol (default: $)
     * @return Formatted price string
     */
    fun formatPrice(price: Double, currencySymbol: String = "$"): String {
        return if (price == 0.0) {
            "FREE"
        } else {
            // Format with 2 decimal places (KMP compatible)
            val rounded = (price * 100).toLong() / 100.0
            val formatted = rounded.toString()
            val withDecimals = if (!formatted.contains('.')) {
                "$formatted.00"
            } else {
                val parts = formatted.split('.')
                val decimal = parts.getOrNull(1) ?: "00"
                "${parts[0]}.${decimal.padEnd(2, '0').take(2)}"
            }
            "$currencySymbol$withDecimals"
        }
    }

    /**
     * Format price range
     */
    fun formatPriceRange(minPrice: Double, maxPrice: Double, currencySymbol: String = "$"): String {
        return when {
            minPrice == 0.0 && maxPrice == 0.0 -> "FREE"
            minPrice == maxPrice -> formatPrice(minPrice, currencySymbol)
            minPrice == 0.0 -> "Up to ${formatPrice(maxPrice, currencySymbol)}"
            else -> "${formatPrice(minPrice, currencySymbol)} - ${formatPrice(maxPrice, currencySymbol)}"
        }
    }

    /**
     * Convert cents to dollars
     */
    fun centsToDollars(cents: Long): Double {
        return cents / 100.0
    }

    /**
     * Convert dollars to cents
     */
    fun dollarsToCents(dollars: Double): Long {
        return (dollars * 100).toLong()
    }
}
