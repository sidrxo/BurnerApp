package com.burner.shared.di

import com.burner.shared.repositories.BookmarkRepository
import com.burner.shared.repositories.EventRepository
import com.burner.shared.repositories.TicketRepository
import com.burner.shared.repositories.TagRepository
import com.burner.shared.repositories.UserRepository
import com.burner.shared.services.AuthService
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime
import kotlin.native.concurrent.ThreadLocal

object KmpHelper {
    private lateinit var client: SupabaseClient

    // Initialize once with keys
    fun initialize(url: String, key: String) {
        client = createSupabaseClient(
            supabaseUrl = url,
            supabaseKey = key
        ) {
            install(Auth)
            install(Postgrest)
            install(Realtime)
        }
    }

    // Getters for Swift (No SupabaseClient argument needed!)
    fun getAuthService(): AuthService {
        val userRepo = UserRepository(client)
        return AuthService(client, userRepo)
    }

    fun getEventRepository(): EventRepository = EventRepository(client)
    fun getTicketRepository(): TicketRepository = TicketRepository(client)
    fun getBookmarkRepository(): BookmarkRepository = BookmarkRepository(client)
    fun getUserRepository(): UserRepository = UserRepository(client)
    fun getTagRepository(): TagRepository = TagRepository(client)
}