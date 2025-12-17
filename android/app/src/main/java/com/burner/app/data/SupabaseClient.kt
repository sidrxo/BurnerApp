package com.burner.app.data

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.realtime.realtime
import io.github.jan.supabase.storage.Storage
import io.github.jan.supabase.storage.storage
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Supabase Client Singleton
 * Matches iOS SupabaseManager configuration
 */
@Singleton
class BurnerSupabaseClient @Inject constructor() {
    val client: SupabaseClient = createSupabaseClient(
        supabaseUrl = "https://lsqlgyyugysvhvxtssik.supabase.co",
        supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzcWxneXl1Z3lzdmh2eHRzc2lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA1NTI2MzEsImV4cCI6MjA0NjEyODYzMX0.I_cePEP-U-ODzIU8R2uGT56WYXFwYnSwNuR46Zq48nU"
    ) {
        install(Auth) {
            // Match iOS configuration
        }
        install(Postgrest)
        install(Realtime)
        install(Storage)
        install(Functions)
    }

    val auth get() = client.auth
    val postgrest get() = client.postgrest
    val realtime get() = client.realtime
    val storage get() = client.storage
    val functions get() = client.functions
}
