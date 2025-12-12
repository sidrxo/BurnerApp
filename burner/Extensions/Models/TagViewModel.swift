import Foundation
import FirebaseFirestore
import Combine

// MARK: - Tag Model
struct Tag: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
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

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

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

    deinit {
        listener?.remove()
    }

    // Fetch tags from Firestore with real-time updates
    func fetchTags() {
        isLoading = true
        error = nil

        // Remove existing listener if any
        listener?.remove()

        // Set up real-time listener
        listener = db.collection("tags")
            .order(by: "order")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                Task { @MainActor in
                    self.isLoading = false

                    if let error = error {
                        self.error = error.localizedDescription
                        // Fall back to default tags if error
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        return
                    }

                    let fetchedTags = documents.compactMap { document -> Tag? in
                        try? document.data(as: Tag.self)
                    }

                    if fetchedTags.isEmpty {
                    } else {
                        self.tags = fetchedTags
                    }
                }
            }
    }

}
