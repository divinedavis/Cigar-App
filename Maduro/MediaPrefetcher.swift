import Foundation
import AVFoundation

/// Warms the URL cache for upcoming photo posts and primes AVURLAssets
/// for upcoming video posts so the For You feed feels instant when
/// swiping. Driven by `feed.scrolledID` changes in `ForYouView`.
@MainActor
final class MediaPrefetcher {
    static let shared = MediaPrefetcher()

    private var photoTasks: [URL: URLSessionDataTask] = [:]
    private var videoAssets: [URL: AVURLAsset] = [:]
    private let session: URLSession

    private init() {
        let cache = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        URLCache.shared = cache
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }

    func prefetchPhoto(_ url: URL) {
        guard photoTasks[url] == nil else { return }
        let request = URLRequest(url: url)
        if URLCache.shared.cachedResponse(for: request) != nil { return }
        let task = session.dataTask(with: request) { [weak self] _, _, _ in
            Task { @MainActor in self?.photoTasks[url] = nil }
        }
        photoTasks[url] = task
        task.resume()
    }

    func prefetchVideo(_ url: URL) {
        guard videoAssets[url] == nil else { return }
        let asset = AVURLAsset(url: url)
        videoAssets[url] = asset
        Task.detached {
            _ = try? await asset.load(.isPlayable, .duration, .tracks)
        }
        if videoAssets.count > 8 {
            videoAssets.removeValue(forKey: videoAssets.keys.first!)
        }
    }
}
