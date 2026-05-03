import Foundation
import SwiftUI

/// Shared state for the For You feed.
///
/// Owned by MainTabView so the floating bottom bar (cigar / comments
/// / messages / post) and the scroll view in ForYouView can talk to
/// each other without prop-drilling. The bar reads `currentItem` to
/// know which post the cigar + comments buttons should act on, and
/// ForYouView writes `scrolledID` as the user pages.
@MainActor
final class FeedController: ObservableObject {
    @Published var items: [FeedItem] = []
    @Published var scrolledID: String?
    @Published var reactedIDs: Set<String> = []
    @Published var isLoadingInitial = false
    private var hasLoaded = false

    func loadInitialIfNeeded(isSubscribed: Bool) async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoadingInitial = true
        defer { isLoadingInitial = false }

        let real: [Post]
        do {
            real = try await PostsRepository.fetchRecent()
        } catch {
            real = []
        }

        let fillerCount = max(0, 50 - real.count)
        let posts = real + SamplePosts.make(count: fillerCount)
        let ads = SampleAds.make(count: 8)
        items = AdSlotPlanner.interleave(posts: posts, ads: ads, isSubscribed: isSubscribed)
        scrolledID = items.first?.id
    }

    var currentItem: FeedItem? {
        guard let id = scrolledID else { return items.first }
        return items.first { $0.id == id }
    }

    var currentPost: Post? {
        if case .post(let p) = currentItem { return p }
        return nil
    }

    var currentAd: AdCreative? {
        if case .ad(let a) = currentItem { return a }
        return nil
    }

    var currentIsReacted: Bool {
        guard let id = currentItem?.id else { return false }
        return reactedIDs.contains(id)
    }

    func toggleReactionOnCurrent() {
        guard let id = currentItem?.id else { return }
        if reactedIDs.contains(id) {
            reactedIDs.remove(id)
        } else {
            reactedIDs.insert(id)
        }
    }
}
