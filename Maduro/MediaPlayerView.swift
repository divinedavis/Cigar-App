import SwiftUI
import UIKit
import AVKit
import Combine

/// Looping, muted, autoplay video view used inside For You feed cells.
///
/// Wraps AVQueuePlayer + AVPlayerLooper so the same clip restarts
/// gaplessly while the cell is visible. SwiftUI's `VideoPlayer` does
/// not loop natively, hence the UIViewRepresentable. Reports load
/// state back through the bindings so PostMediaView can show a
/// spinner / fallback instead of a silent black rectangle when the
/// asset is still buffering or fails to load.
struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL
    @Binding var isReady: Bool
    @Binding var didFail: Bool

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.onReady = { Task { @MainActor in self.isReady = true } }
        view.onFail = { Task { @MainActor in self.didFail = true } }
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
    private var statusObservation: NSKeyValueObservation?

    var onReady: (() -> Void)?
    var onFail: (() -> Void)?

    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    func configure(url: URL) {
        guard url != currentURL else { return }
        currentURL = url
        statusObservation?.invalidate()
        statusObservation = nil

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: item)
        player.isMuted = true
        self.player = player
        self.looper = AVPlayerLooper(player: player, templateItem: item)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            switch item.status {
            case .readyToPlay: self?.onReady?()
            case .failed: self?.onFail?()
            default: break
            }
        }
        player.play()
    }

    func teardown() {
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        player = nil
        looper = nil
        currentURL = nil
        playerLayer.player = nil
    }
}

/// Renders either a remote photo or an autoplaying looping video,
/// based on `Post.MediaKind`. Always fills its bounds and shows
/// loading / error feedback so a slow or failed fetch is never
/// silent.
struct PostMediaView: View {
    let url: URL
    let kind: Post.MediaKind

    @State private var videoReady = false
    @State private var videoFailed = false

    var body: some View {
        GeometryReader { geo in
            switch kind {
            case .video:
                ZStack {
                    Color.black
                    LoopingVideoPlayer(url: url, isReady: $videoReady, didFail: $videoFailed)
                        .opacity(videoReady ? 1 : 0)
                    if !videoReady && !videoFailed {
                        ProgressView().tint(.white)
                    }
                    if videoFailed {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Couldn't load this clip")
                                .font(.footnote).foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .onChange(of: url) { _, _ in
                    videoReady = false
                    videoFailed = false
                }
            case .photo:
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.black
                            ProgressView().tint(.white)
                        }
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Color.brown.opacity(0.4)
                    @unknown default:
                        Color.black
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
        }
    }
}
