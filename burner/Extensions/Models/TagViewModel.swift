import Foundation
import Combine
import Supabase

// MARK: - Tag Model
struct Tag: Identifiable, Codable, Sendable {
    var id: String?
    var name: String
    var nameLowercase: String?
    var description: String?
    var color: String?
    var order: Int
    var active: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nameLowercase
        case description
        case color
        case order
        case active
        case createdAt
        case updatedAt
    }
    
    // Custom decoder to handle Firebase timestamp format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nameLowercase = try container.decodeIfPresent(String.self, forKey: .nameLowercase)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        
        // Handle order as either Int or String
        if let orderInt = try? container.decode(Int.self, forKey: .order) {
            order = orderInt
        } else if let orderString = try? container.decode(String.self, forKey: .order),
                  let orderInt = Int(orderString) {
            order = orderInt
        } else {
            order = 0
        }
        
        active = try container.decode(Bool.self, forKey: .active)
        
        // Handle Firebase timestamp format or regular Date
        createdAt = decodeFirebaseDate(from: container, forKey: .createdAt)
        updatedAt = decodeFirebaseDate(from: container, forKey: .updatedAt)
    }
    
    private func decodeFirebaseDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Date? {
        // Try regular Date first
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        
        // Try Firebase timestamp string format
        if let timestampString = try? container.decode(String.self, forKey: key),
           let data = timestampString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let seconds = json["_seconds"] as? TimeInterval {
            return Date(timeIntervalSince1970: seconds)
        }
        
        return nil
    }
}

// MARK: - Tag View Model
@MainActor
class TagViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let client = SupabaseManager.shared.client

    // Display-ready tags (active only, sorted by order)
    var displayTags: [String] {
        tags
            .filter { $0.active }
            .sorted { $0.order < $1.order }
            .map { $0.name }
    }

    init() {
        fetchTags()
    }

    // Fetch tags from Supabase
    func fetchTags() {
        isLoading = true
        error = nil

        Task {
            do {
                let fetchedTags: [Tag] = try await client
                    .from("tags")
                    .select()
                    .order("order", ascending: true)
                    .order("name", ascending: true)
                    .execute()
                    .value

                self.tags = fetchedTags
                self.isLoading = false
            } catch {
                print("❌ Error fetching tags: \(error)")
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
