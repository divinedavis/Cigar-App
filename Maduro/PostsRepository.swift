import Foundation

/// Reads `public.posts` rows from Supabase and maps them into the
/// app's `Post` model. The For You feed calls `fetchRecent` on
/// startup and merges the result with sample data so the feed stays
/// populated while real uploads are still trickling in.
enum PostsRepository {
    static func fetchRecent(limit: Int = 50) async throws -> [Post] {
        let rows: [PostRow] = try await supabase
            .from("posts")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.compactMap { $0.asPost }
    }
}

private struct PostRow: Decodable {
    let id: UUID
    let author_id: UUID
    let media_url: String
    let media_kind: String
    let caption: String?
    let cigar_id: UUID?
    let store_id: UUID?
    let created_at: Date
    let cigar_reaction_count: Int
    let comment_count: Int
    let save_count: Int

    var asPost: Post? {
        guard let mediaURL = URL(string: media_url),
              let kind = Post.MediaKind(rawValue: media_kind) else { return nil }
        return Post(
            id: id,
            authorID: author_id,
            mediaURL: mediaURL,
            mediaKind: kind,
            caption: caption ?? "",
            cigarID: cigar_id,
            storeID: store_id,
            createdAt: created_at,
            cigarReactionCount: cigar_reaction_count,
            commentCount: comment_count,
            saveCount: save_count,
            viewerHasReacted: false
        )
    }
}
