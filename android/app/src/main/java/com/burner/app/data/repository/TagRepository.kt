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
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import android.util.Log
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TagRepository @Inject constructor(
    private val supabase: BurnerSupabaseClient
) {
    // Get all active tags (real-time)
    val allTags: Flow<List<Tag>> = flow {
        Log.d("TagRepository", "allTags Flow: Starting initial fetch")
        // Emit initial tags immediately (fixes infinite loading issue)
        val initialTags = getTagsInternal()
        Log.d("TagRepository", "allTags Flow: Initial fetch returned ${initialTags.size} tags")
        emit(initialTags)

        // Then listen for realtime updates
        Log.d("TagRepository", "allTags Flow: Setting up realtime subscription")
        supabase.realtime
            .channel("tags")
            .postgresChangeFlow<PostgresAction>(schema = "public") {
                table = "tags"
            }
            .collect {
                Log.d("TagRepository", "allTags Flow: Realtime update received, fetching fresh data")
                emit(getTagsInternal())
            }
    }

    // Get tags once
    suspend fun getTags(): List<Tag> {
        return getTagsInternal()
    }

    private suspend fun getTagsInternal(): List<Tag> {
        return try {
            Log.d("TagRepository", "getTagsInternal: Fetching tags from Supabase")
            val tags = supabase.postgrest.from("tags")
                .select(columns = Columns.ALL) {
                    filter {
                        eq("active", true)
                    }
                    order("order", Order.ASCENDING)
                }
                .decodeList<Tag>()
                .ifEmpty {
                    Log.d("TagRepository", "getTagsInternal: No tags in database, using default genres")
                    Tag.defaultGenres
                }
            Log.d("TagRepository", "getTagsInternal: Fetched ${tags.size} tags")
            tags
        } catch (e: Exception) {
            Log.e("TagRepository", "getTagsInternal: Error fetching tags", e)
            Tag.defaultGenres
        }
    }
}