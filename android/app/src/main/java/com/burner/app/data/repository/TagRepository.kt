package com.burner.app.data.repository

import com.burner.app.data.BurnerSupabaseClient
import com.burner.app.data.models.Tag
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TagRepository @Inject constructor(
    private val supabase: BurnerSupabaseClient
) {
    // Get all active tags (real-time)
    val allTags: Flow<List<Tag>> = supabase.realtime
        .channel("tags")
        .postgresChangeFlow<PostgresAction>(schema = "public") {
            table = "tags"
        }
        .map {
            getTagsInternal()
        }

    // Get tags once
    suspend fun getTags(): List<Tag> {
        return getTagsInternal()
    }

    private suspend fun getTagsInternal(): List<Tag> {
        return try {
            supabase.postgrest.from("tags")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("active", true)
                    }
                    order("order", Order.ASCENDING)
                }
                .decodeList<Tag>()
                .ifEmpty { Tag.defaultGenres }
        } catch (e: Exception) {
            Tag.defaultGenres
        }
    }
}