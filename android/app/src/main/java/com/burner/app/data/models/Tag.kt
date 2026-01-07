package com.burner.app.data.models

import kotlinx.serialization.Serializable

/**
 * Tag/Genre model matching iOS Tag struct
 * Updated for Supabase
 */
@Serializable
data class Tag(
    val id: String? = null,
    val name: String = "",
    val order: Int = 0,
    val active: Boolean = true,
    val color: String? = null,
    val description: String? = null
) {
    companion object {
        // Default genres to use if none loaded from Supabase
        val defaultGenres = listOf(
            Tag(id = "electronic", name = "Electronic", order = 1),
            Tag(id = "house", name = "House", order = 2),
            Tag(id = "techno", name = "Techno", order = 3),
            Tag(id = "hiphop", name = "Hip Hop", order = 4),
            Tag(id = "rnb", name = "R&B", order = 5),
            Tag(id = "pop", name = "Pop", order = 6),
            Tag(id = "rock", name = "Rock", order = 7),
            Tag(id = "indie", name = "Indie", order = 8),
            Tag(id = "jazz", name = "Jazz", order = 9),
            Tag(id = "classical", name = "Classical", order = 10),
            Tag(id = "latin", name = "Latin", order = 11),
            Tag(id = "afrobeats", name = "Afrobeats", order = 12),
            Tag(id = "dnb", name = "Drum & Bass", order = 13),
            Tag(id = "reggae", name = "Reggae", order = 14),
            Tag(id = "country", name = "Country", order = 15),
            Tag(id = "folk", name = "Folk", order = 16)
        )
    }
}
