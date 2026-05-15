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
        .refreshable {
            await feed.refresh(isSubscribed: session.isSubscribed)
        }
        .ignoresSafeArea()
        .background(.black)
        .overlay {
            if feed.isLoadingInitial && feed.items.isEmpty {
                ProgressView().tint(.white)
            }
        }
        .task {
            await feed.loadInitialIfNeeded(isSubscribed: session.isSubscribed)
            prefetchAhead(from: feed.scrolledID)
        }
        .onChange(of: feed.scrolledID) { _, newID in
            prefetchAhead(from: newID)
        }
    }

    private func prefetchAhead(from id: String?) {
        guard let id, let idx = feed.items.firstIndex(where: { $0.id == id }) else { return }
        var photosQueued = 0
        var videosQueued = 0
        let maxPhotos = 5
        let maxVideos = 2
        for item in feed.items.dropFirst(idx + 1) {
            let url: URL
            let kind: Post.MediaKind
            switch item {
            case .post(let p): url = p.mediaURL; kind = p.mediaKind
            case .ad(let a): url = a.mediaURL; kind = a.mediaKind
            }
            switch kind {
            case .photo where photosQueued < maxPhotos:
                MediaPrefetcher.shared.prefetchPhoto(url)
                photosQueued += 1
            case .video where videosQueued < maxVideos:
                MediaPrefetcher.shared.prefetchVideo(url)
                videosQueued += 1
            default:
                break
            }
            if photosQueued >= maxPhotos && videosQueued >= maxVideos { break }
        }
    }

    @ViewBuilder
    private func feedCell(_ item: FeedItem) -> some View {
        switch item {
        case .post(let post): PostCell(post: post)
        case .ad(let ad): AdCell(ad: ad)
        }
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

            // Live-stream-style chat overlay: recent reactions fading
            // upward, with the post's own caption as the freshest line.
            ChatOverlay(lines: chatLines)
                .padding(.horizontal, 20)
                .padding(.bottom, 96)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var chatLines: [ChatLine] {
        FeedChat.lines(
            seed: post.id.uuidString,
            authorName: "@cigar_fan_\(post.authorID.uuidString.prefix(4).lowercased())",
            caption: post.caption
        )
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
                    .lineLimit(1)
                Text(ad.headline)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.95))
                    .lineLimit(3)
                Button(ad.ctaLabel) {}
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.bottom, 96)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

// MARK: - Live-stream chat overlay

struct ChatLine: Identifiable {
    let id = UUID()
    let name: String
    let text: String
}

/// Stack of recent chat lines, oldest at top and dimmed, newest at
/// bottom and fully opaque — the look from the live-broadcast mockup.
private struct ChatOverlay: View {
    let lines: [ChatLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(Array(lines.enumerated()), id: \.element.id) { idx, line in
                HStack(alignment: .center, spacing: 10) {
                    SeededAvatar(seed: line.name, size: 30)
                    (Text(line.name + " ")
                        .font(.system(size: 16, weight: .semibold))
                     + Text(line.text)
                        .font(.system(size: 16, weight: .regular)))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.65), radius: 3, y: 1)
                }
                .opacity(opacity(for: idx, of: lines.count))
            }
        }
    }

    private func opacity(for idx: Int, of count: Int) -> Double {
        guard count > 1 else { return 1 }
        return 0.35 + 0.65 * Double(idx) / Double(count - 1)
    }
}

/// Deterministic placeholder chat for a feed cell. Seeded by the
/// item id so a given post always shows the same lines.
enum FeedChat {
    private static let names = [
        "Natasha", "Chelsea", "Lisa", "Regina", "Hall", "Marcus",
        "Diego", "Priya", "Theo", "Amara", "Jules", "Devon"
    ]
    private static let blurbs = [
        "joined the chat",
        "🔥🔥",
        "that wrapper is gorgeous",
        "where'd you grab that one?",
        "perfect draw on those",
        "pairs great with bourbon",
        "joined the chat",
        "ash game strong 💪",
        "need to visit that lounge"
    ]

    static func lines(seed: String, authorName: String, caption: String) -> [ChatLine] {
        var state = 5381
        for u in seed.unicodeScalars { state = ((state << 5) &+ state) &+ Int(u.value) }
        func next(_ modulo: Int) -> Int {
            state = abs((state &* 1103515245) &+ 12345)
            return state % max(modulo, 1)
        }

        var result: [ChatLine] = []
        for _ in 0..<4 {
            result.append(ChatLine(name: names[next(names.count)],
                                   text: blurbs[next(blurbs.count)]))
        }
        result.append(ChatLine(name: authorName, text: caption))
        return result
    }
}

// MARK: - Shared building blocks

/// Deterministic colored avatar disc. Used by both the feed chat
/// overlay and the top author pill in `MainTabView`.
struct SeededAvatar: View {
    let seed: String
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundStyle(.white)
            )
            .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 1.5))
    }

    private var color: Color {
        let palette: [Color] = [.orange, .brown, .indigo, .teal, .pink, .purple, .blue, .green]
        var hash = 5381
        for u in seed.unicodeScalars { hash = ((hash << 5) &+ hash) &+ Int(u.value) }
        return palette[abs(hash) % palette.count]
    }

    private var initial: String {
        let cleaned = seed.drop(while: { $0 == "@" })
        return String(cleaned.prefix(1)).uppercased()
    }
}

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
