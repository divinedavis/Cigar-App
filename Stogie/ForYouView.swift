import SwiftUI

struct ForYouView: View {
    @EnvironmentObject var session: SessionStore
    @State private var items: [FeedItem] = []

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    feedCell(item)
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .ignoresSafeArea()
        .background(.black)
        .task { if items.isEmpty { items = buildInitialFeed() } }
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

private struct PostCell: View {
    let post: Post
    @State private var reacted: Bool = false
    @State private var reactionCount: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            PostMediaView(url: post.mediaURL, kind: post.mediaKind)

            // Bottom gradient so caption stays legible over any media.
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            HStack(alignment: .bottom, spacing: 12) {
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
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 22) {
                    CigarReactionButton(count: reactionCount, isOn: reacted) {
                        reacted.toggle()
                        reactionCount += reacted ? 1 : -1
                    }
                    Button(action: {}) {
                        VStack(spacing: 2) {
                            Image(systemName: "bubble.right.fill").font(.title2)
                            Text("\(post.commentCount)").font(.caption2)
                        }.foregroundStyle(.white)
                    }
                    Button(action: {}) {
                        VStack(spacing: 2) {
                            Image(systemName: "bookmark.fill").font(.title2)
                            Text("\(post.saveCount)").font(.caption2)
                        }.foregroundStyle(.white)
                    }
                    Button(action: {}) {
                        Image(systemName: "arrowshape.turn.up.right.fill").font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 110)
        }
        .onAppear {
            reacted = post.viewerHasReacted
            reactionCount = post.cigarReactionCount
        }
    }
}

private struct AdCell: View {
    let ad: AdCreative

    var body: some View {
        ZStack(alignment: .bottom) {
            PostMediaView(url: ad.mediaURL, kind: ad.mediaKind)

            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                Text("Sponsored")
                    .font(.caption).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.yellow.opacity(0.85), in: .capsule)
                    .foregroundStyle(.black)
                Text(ad.businessName)
                    .font(.headline).foregroundStyle(.white)
                Text(ad.headline)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.95))
                Button(ad.ctaLabel) {}
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.bottom, 110)
        }
    }
}
