import Foundation

struct AppUser: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String
    var displayName: String
    var bio: String
    var avatarURL: URL?
    var dateOfBirth: Date
    var accountType: AccountType
    var isVerified: Bool

    enum AccountType: String, Codable { case personal, business }
}

struct Post: Identifiable, Codable, Equatable {
    let id: UUID
    let authorID: UUID
    let mediaURL: URL
    let mediaKind: MediaKind
    let caption: String
    let cigarID: UUID?
    let storeID: UUID?
    let createdAt: Date
    var cigarReactionCount: Int
    var commentCount: Int
    var saveCount: Int
    var viewerHasReacted: Bool

    enum MediaKind: String, Codable { case photo, video }
}

struct Cigar: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let brand: String
    let line: String
    let vitola: String?

    var displayName: String {
        if let vitola, !vitola.isEmpty {
            return "\(brand) \(line) — \(vitola)"
        }
        return "\(brand) \(line)"
    }
}

struct CigarStore: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

enum FeedItem: Identifiable, Equatable {
    case post(Post)
    case ad(AdCreative)

    var id: String {
        switch self {
        case .post(let p): return "post-\(p.id.uuidString)"
        case .ad(let a): return "ad-\(a.id.uuidString)"
        }
    }
}

struct AdCreative: Identifiable, Codable, Equatable {
    let id: UUID
    let businessID: UUID
    let businessName: String
    let mediaURL: URL
    let mediaKind: Post.MediaKind
    let headline: String
    let ctaLabel: String
    let ctaURL: URL?
}
