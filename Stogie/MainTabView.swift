import SwiftUI

/// Root in-app shell. Replaces the system TabView with TIDE-style
/// chrome: a small profile circle in the top-right and a single
/// floating pill bar at the bottom with four buttons that act on
/// whichever post is currently snapped in the For You feed.
struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var feed = FeedController()

    @State private var showingCreate = false
    @State private var showingComments = false
    @State private var showingProfile = false

    var body: some View {
        ZStack {
            ForYouView()
                .environmentObject(feed)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button { showingProfile = true } label: {
                        ProfileCircle(user: session.currentUser)
                    }
                    .padding(.trailing, 18)
                }
                Spacer()
            }
            .padding(.top, 8)

            VStack {
                Spacer()
                FloatingTabBar(
                    isReacted: feed.currentIsReacted,
                    onCigar: { feed.toggleReactionOnCurrent() },
                    onComments: { showingComments = true },
                    onPost: { showingCreate = true }
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 14)
            }
        }
        .fullScreenCover(isPresented: $showingCreate) {
            CreatePostView()
        }
        .sheet(isPresented: $showingComments) {
            commentsSheet
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

// MARK: - Top-right profile circle

private struct ProfileCircle: View {
    let user: AppUser?

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [.orange, .yellow, .pink, .purple, .blue, .green, .orange],
                        center: .center
                    )
                )
                .frame(width: 44, height: 44)
                .blur(radius: 1.5)

            Circle()
                .fill(.brown.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initials)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                )
        }
        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
    }

    private var initials: String {
        guard let user else { return "S" }
        let parts = user.displayName.split(separator: " ").prefix(2)
        let value = parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
        return value.isEmpty ? "S" : value
    }
}

// MARK: - Floating bottom pill

private struct FloatingTabBar: View {
    let isReacted: Bool
    let onCigar: () -> Void
    let onComments: () -> Void
    let onPost: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(action: onCigar) {
                CigarTabIcon(isOn: isReacted)
            }
            tabButton(action: onComments) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            tabButton(action: onPost) {
                Image(systemName: "plus.square.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay(
            Capsule().stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }

    @ViewBuilder
    private func tabButton<Content: View>(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .contentShape(Rectangle())
        }
    }
}

private struct CigarTabIcon: View {
    let isOn: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? Color.orange : Color.white)
                .frame(width: 30, height: 11)
            Circle()
                .fill(isOn ? Color.yellow : Color.gray.opacity(0.85))
                .frame(width: 10, height: 10)
                .offset(x: -15)
            if isOn {
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
                    .offset(x: -15)
            }
        }
        .shadow(color: isOn ? .orange.opacity(0.6) : .clear, radius: 5)
    }
}
