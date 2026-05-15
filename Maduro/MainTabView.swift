import SwiftUI

/// Root in-app shell. Live-broadcast-styled chrome over the For You
/// feed: a translucent top bar (back / author pill / overflow menu),
/// a viewer-count pill, and a bottom message composer. Post, Search
/// and Profile moved into the overflow menu so the composer can match
/// the mockup's heart + emoji + message-field layout.
struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var feed = FeedController()

    @State private var showingCreate = false
    @State private var showingComments = false
    @State private var showingProfile = false
    @State private var showingSearch = false

    var body: some View {
        ZStack {
            ForYouView()
                .environmentObject(feed)
                .ignoresSafeArea()

            // Top scrim keeps the chrome legible over bright media.
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.45), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 170)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 10) {
                topBar
                if let post = feed.currentPost {
                    viewerPill(count: post.viewCount)
                }
                Spacer()
            }
            .padding(.top, 8)

            VStack {
                Spacer()
                composerBar
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
            }
        }
        .fullScreenCover(isPresented: $showingCreate) {
            CreatePostView()
        }
        .sheet(isPresented: $showingComments) {
            commentsSheet
        }
        .sheet(isPresented: $showingSearch) {
            SearchView()
        }
        .fullScreenCover(isPresented: $showingProfile) {
            NavigationStack {
                ProfileView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showingProfile = false
                            } label: {
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.white)
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            HStack {
                Spacer()
                Menu {
                    Button { showingCreate = true } label: {
                        Label("New Post", systemImage: "plus.square")
                    }
                    Button { showingSearch = true } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    Button { showingProfile = true } label: {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                } label: {
                    CircleIcon(systemName: "ellipsis", size: 46)
                }
            }
            Button { showingProfile = true } label: {
                AuthorPill(handle: authorHandle)
            }
        }
        .padding(.horizontal, 18)
    }

    private func viewerPill(count: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "eye.fill").font(.caption2)
            Text(abbreviatedCount(count)).font(.caption).bold()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
    }

    /// 11_692 -> "11.7K", 299_783 -> "299.8K".
    private func abbreviatedCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000
            return String(format: "%.1fK", thousands)
        }
        return "\(count)"
    }

    // MARK: - Bottom composer

    private var composerBar: some View {
        HStack(spacing: 10) {
            Button { feed.toggleReactionOnCurrent() } label: {
                CircleIcon(
                    systemName: feed.currentIsReacted ? "heart.fill" : "heart",
                    size: 50,
                    tint: feed.currentIsReacted ? .red : .white
                )
            }
            Button { showingComments = true } label: {
                CircleIcon(systemName: "face.smiling", size: 50)
            }
            ShareLink(item: shareContent) {
                CircleIcon(systemName: "square.and.arrow.up", size: 50)
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private var shareContent: String {
        if let post = feed.currentPost {
            return "Check out this cigar moment on Maduro: \(post.caption)"
        }
        if let ad = feed.currentAd {
            return "\(ad.businessName) on Maduro: \(ad.headline)"
        }
        return "Check out Maduro — a community for cigar lovers."
    }

    private var authorHandle: String {
        if let post = feed.currentPost {
            return "@cigar_fan_\(post.authorID.uuidString.prefix(4).lowercased())"
        }
        if let ad = feed.currentAd {
            return ad.businessName
        }
        return "@maduro"
    }

    @ViewBuilder
    private var commentsSheet: some View {
        if let post = feed.currentPost {
            CommentsView(title: post.caption, initialCount: post.commentCount)
        } else if let ad = feed.currentAd {
            CommentsView(title: ad.headline, initialCount: 0)
        } else {
            CommentsView(title: "", initialCount: 0)
        }
    }
}

// MARK: - Reusable chrome

/// Translucent circular icon — the back / overflow / heart / emoji
/// buttons in the live-broadcast layout.
private struct CircleIcon: View {
    let systemName: String
    var size: CGFloat = 48
    var tint: Color = .white

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }
}

/// White "Host"-style pill showing the current post's author.
private struct AuthorPill: View {
    let handle: String

    var body: some View {
        HStack(spacing: 7) {
            SeededAvatar(seed: handle, size: 30)
            Text(handle)
                .font(.caption).bold()
                .foregroundStyle(.black)
                .lineLimit(1)
        }
        .padding(.leading, 5)
        .padding(.trailing, 12)
        .padding(.vertical, 5)
        .background(.white, in: .capsule)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
    }
}
