import Foundation

/// Inserts ads into the For You feed for non-subscribed users.
///
/// Rules (from product spec):
/// - Random slot between every 4 and 10 posts.
/// - Never more than 1 ad per 4 consecutive posts (enforced by the min gap).
/// - Subscribed / paid users see no ads.
enum AdSlotPlanner {
    static let minGap = 4
    static let maxGap = 10

    static func interleave(posts: [Post], ads: [AdCreative], isSubscribed: Bool) -> [FeedItem] {
        let postItems = posts.map(FeedItem.post)
        guard !isSubscribed, !ads.isEmpty else { return postItems }

        var result: [FeedItem] = []
        var adIndex = 0
        var sincePostCount = 0
        var nextGap = Int.random(in: minGap...maxGap)

        for post in posts {
            result.append(.post(post))
            sincePostCount += 1
            if sincePostCount >= nextGap, adIndex < ads.count {
                result.append(.ad(ads[adIndex % ads.count]))
                adIndex += 1
                sincePostCount = 0
                nextGap = Int.random(in: minGap...maxGap)
            }
        }
        return result
    }
}
