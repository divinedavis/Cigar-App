import SwiftUI

struct ForYouView: View {
    @EnvironmentObject var session: SessionStore
    @State private var items: [FeedItem] = []
    @State private var currentIndex: Int = 0

    var body: some View {
        GeometryReader { geo in
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    feedCell(item)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .rotationEffect(.degrees(-90))
                        .tag(idx)
                }
            }
            .frame(width: geo.size.height, height: geo.size.width)
            .rotationEffect(.degrees(90), anchor: .topLeading)
            .offset(x: geo.size.width)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .background(.black)
        }
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
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.brown.opacity(0.6), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                Text("@cigar_fan_\(post.authorID.uuidString.prefix(4))")
                    .font(.headline).foregroundStyle(.white)
                Text(post.caption)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.9))
                if let cigarID = post.cigarID,
                   let cigar = CigarCatalog.all.first(where: { $0.id == cigarID }) {
                    Label(cigar.displayName, systemImage: "flame.fill")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 120)

            VStack(spacing: 22) {
                Spacer()
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
            .padding(.trailing, 14)
            .padding(.bottom, 120)
            .frame(maxWidth: .infinity, alignment: .trailing)
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
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(red: 0.12, green: 0.08, blue: 0.04), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                Text("Sponsored")
                    .font(.caption).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.yellow.opacity(0.8), in: .capsule)
                    .foregroundStyle(.black)
                Text(ad.businessName).font(.headline).foregroundStyle(.white)
                Text(ad.headline).font(.subheadline).foregroundStyle(.white.opacity(0.9))
                Button(ad.ctaLabel) {}
                    .buttonStyle(.borderedProminent).tint(.orange)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 120)
        }
    }
}
