import Foundation
import Combine
import Supabase
import Shared

// MARK: - Type Alias
typealias Tag = Shared.Tag

// MARK: - Swift Extensions for KMP Tag
extension Shared.Tag {
    /// Convert KMP createdAt to Swift Date (if needed)
    var createdAt: Date? {
        // KMP Tag doesn't have createdAt/updatedAt in the model
        // This is here for compatibility if needed in the future
        return nil
    }

    /// Convert KMP updatedAt to Swift Date (if needed)
    var updatedAt: Date? {
        return nil
    }
}

// MARK: - Tag View Model
@MainActor
class TagViewModel: ObservableObject {
    @Published var tags: [Shared.Tag] = []
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
                let fetchedTags: [Shared.Tag] = try await client
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
