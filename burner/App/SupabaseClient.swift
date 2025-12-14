import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseUrl = URL(string: "https://lsqlgyyugysvhvxtssik.supabase.co")!
        // Note: It is generally safer to inject these keys via environment variables or a configuration file rather than hardcoding.
        let supabaseKey = "sb_publishable_gSNN1pd-OujICXo_6_WmUg_5rhwRw3L"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
