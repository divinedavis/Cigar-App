import SwiftUI

struct ForYouView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var feed: FeedController

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(feed.items) { item in
                    feedCell(item)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $feed.scrolledID)
        .ignoresSafeArea()
        .background(.black)
        .task {
            if feed.items.isEmpty {
                feed.items = buildInitialFeed()
                feed.scrolledID = feed.items.first?.id
            }
        }
    }

    @ViewBuilder
    private func feedCell(_ item: FeedItem) -> some View {
        switch item {
        case .post(let post): PostCell(post: post)
        case .ad(let ad): AdCell(ad: ad)
        }
    }

    private func buildInitialFeed() -> [FeedItem] {
        let posts = SamplePosts.make(count: 30)
        let ads = SampleAds.make(count: 6)
        return AdSlotPlanner.interleave(posts: posts, ads: ads, isSubscribed: session.isSubscribed)
    }
}

// MARK: - Cells

private struct PostCell: View {
    let post: Post

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PostMediaView(url: post.mediaURL, kind: post.mediaKind)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            BottomDimGradient()

            VStack(alignment: .leading, spacing: 6) {
                Text("@cigar_fan_\(post.authorID.uuidString.prefix(4).lowercased())")
                    .font(.headline).foregroundStyle(.white)
                Text(post.caption)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.95))
                    .lineLimit(3)
                if let cigarID = post.cigarID,
                   let cigar = CigarCatalog.all.first(where: { $0.id == cigarID }) {
                    Label(cigar.displayName, systemImage: "flame.fill")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 110)
            .padding(.trailing, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

private struct AdCell: View {
    let ad: AdCreative

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PostMediaView(url: ad.mediaURL, kind: ad.mediaKind)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            BottomDimGradient()

            VStack(alignment: .leading, spacing: 8) {
                Text("Sponsored")
                    .font(.caption).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.yellow.opacity(0.85), in: .capsule)
                    .foregroundStyle(.black)
                Text(ad.businessName)
                    .font(.headline).foregroundStyle(.white)
                Text(ad.headline)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.95))
                    .lineLimit(3)
                Button(ad.ctaLabel) {}
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 110)
            .padding(.trailing, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

// MARK: - Shared building blocks

private struct BottomDimGradient: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.65)],
            startPoint: .center,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
