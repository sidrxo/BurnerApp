import Foundation
import Supabase
import PostgREST

// MARK: - 1. Global Supabase Client Initialization
// NOTE: REPLACE THESE PLACEHOLDERS WITH YOUR ACTUAL URL AND ANON KEY
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://lsqlgyyugysvhvxtssik.supabase.co")!,
    supabaseKey: "sb_publishable_gSNN1pd-OujICXo_6_WmUg_5rhwRw3L"
)

// Fixes: Value of type 'Data' has no member 'dictionary'
extension Encodable {
    var dictionary: [String: Any]? {
        // Use ISO8601 for encoding dates to maintain compatibility with Postgres timestamps
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 
        
        guard let data = try? encoder.encode(self),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
              let dict = jsonObject as? [String: Any] else {
            return nil
        }
        return dict
    }
}

// Fixes: Cannot infer contextual base in reference to member 'eq' and 'exact'
// Provides a clean way to decode the PostgREST response body directly into Swift models.
extension PostgrestResponse {
    func decode<T: Decodable>(as type: T.Type = T.self) throws -> T {
        // PostgRESTResponse value is the data payload, which is an array or object.
        let data = try JSONSerialization.data(withJSONObject: self.value, options: [])
        let decoder = JSONDecoder()
        
        // Use a consistent date decoding strategy for Postgres timestamps
        decoder.dateDecodingStrategy = .iso8601 
        
        return try decoder.decode(T.self, from: data)
    }
}
