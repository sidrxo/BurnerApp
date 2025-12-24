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
            String.format("%s%.2f", currencySymbol, price)
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
