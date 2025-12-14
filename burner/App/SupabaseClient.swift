import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseUrl = URL(string: "https://lsqlgyyugysvhvxtssik.supabase.co")!
        let supabaseKey = "sb_publishable_gSNN1pd-OujICXo_6_WmUg_5rhwRw3L"
        
        self.client = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: supabaseKey)
    }
}
