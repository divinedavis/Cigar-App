import SwiftUI
import UIKit
import AVKit

/// Looping, muted, autoplay video view used inside For You feed cells.
///
/// Wraps AVQueuePlayer + AVPlayerLooper so the same clip restarts
/// gaplessly while the cell is visible. SwiftUI's `VideoPlayer` does
/// not loop natively, hence the UIViewRepresentable.
struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.configure(url: url)
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: ()) {
        uiView.teardown()
    }
}

final class PlayerContainerView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    func configure(url: URL) {
        guard url != currentURL else { return }
        currentURL = url
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none
        self.player = player
        self.looper = AVPlayerLooper(player: player, templateItem: item)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        player.play()
    }

    func teardown() {
        player?.pause()
        player = nil
        looper = nil
        currentURL = nil
        playerLayer.player = nil
    }
}

/// Renders either a remote photo or an autoplaying looping video,
/// based on `Post.MediaKind`. Always fills its bounds.
struct PostMediaView: View {
    let url: URL
    let kind: Post.MediaKind

    var body: some View {
        switch kind {
        case .video:
            LoopingVideoPlayer(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        case .photo:
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.black
                        ProgressView().tint(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure:
                    Color.brown.opacity(0.4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    Color.black
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .ignoresSafeArea()
        }
    }
}
