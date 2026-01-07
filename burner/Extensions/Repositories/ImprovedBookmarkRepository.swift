import Swift
import Combine
import Supabase
import UIKit

// IMPROVED: BookmarkRepository without realtime
@MainActor
class BookmarkRepository: BaseRepository, BookmarkRepositoryProtocol {

    // No realtime channel needed!
    // private var currentChannel: RealtimeChannelV2? ❌ REMOVED
    private var cachedBookmarks: [BookmarkData] = []

    // Simple fetch - no subscription
    func fetchBookmarks(userId: String) async throws -> [BookmarkData] {
        let bookmarks: [BookmarkData] = try await client
            .from("bookmarks")
            .select()
            .eq("user_id", value: userId)
            .order("bookmarked_at", ascending: false)
            .execute()
            .value

        cachedBookmarks = bookmarks
        return bookmarks
    }

    // Add bookmark (instant local update, sync to server)
    func addBookmark(userId: String, bookmark: BookmarkData) async throws {
        // Optimistically add to cache
        cachedBookmarks.insert(bookmark, at: 0)

        // Sync to server
        do {
            try await client
                .from("bookmarks")
                .insert(bookmark)
                .execute()
        } catch {
            // Rollback on error
            cachedBookmarks.removeAll { $0.id == bookmark.id }
            throw error
        }
    }

    // Remove bookmark (instant local update, sync to server)
    func removeBookmark(userId: String, eventId: String) async throws {
        // Find and remove from cache
        guard let index = cachedBookmarks.firstIndex(where: { $0.eventId == eventId }) else {
            return
        }
        let removed = cachedBookmarks.remove(at: index)

        // Sync to server
        do {
            try await client
                .from("bookmarks")
                .delete()
                .eq("user_id", value: userId)
                .eq("event_id", value: eventId)
                .execute()
        } catch {
            // Rollback on error
            cachedBookmarks.insert(removed, at: index)
            throw error
        }
    }

    // Get cached bookmarks (instant)
    func getCachedBookmarks() -> [BookmarkData] {
        return cachedBookmarks
    }
}
