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
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
