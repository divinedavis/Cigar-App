import Foundation

// Placeholder content used while the For You feed is not yet wired
// to Supabase. Delete once the real fetch path is live.
//
// Videos come from Google's public "gtv-videos-bucket" sample set
// — widely used in iOS sample code and stable. Photos come from
// picsum.photos seeded so each post gets a stable image.

private enum SampleMedia {
    // Google's gtv-videos-bucket started returning 403 in 2026; switched to
    // test-videos.co.uk's small Creative Commons clips, which return 200
    // directly and weigh ~1MB each so the For You feed loads fast.
    static let videos: [URL] = [
        "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4",
        "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4",
        "https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4",
        "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4",
        "https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4",
        "https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_1MB.mp4"
    ].compactMap(URL.init(string:))

    static func photo(seed: String) -> URL {
        URL(string: "https://picsum.photos/seed/\(seed)/800/1400")!
    }
}

enum SamplePosts {
    static func make(count: Int) -> [Post] {
        let captions = [
            "Sunday afternoon with a 1964 Anniversary.",
            "First OpusX of the year. Worth the wait.",
            "Padron 1926 pairs perfectly with this bourbon.",
            "New humidor, who dis.",
            "Friday night at the lounge.",
            "Ash game strong.",
            "Two-hour smoke and zero regrets.",
            "Don Carlos No. 3, Maduro wrapper, perfect draw.",
            "Bourbon and a Behike. Don't tell my wife.",
            "Cigar trip to the Dominican was unreal."
        ]
        let videos = SampleMedia.videos
        return (0..<count).map { i in
            let videoURL = videos[Int.random(in: 0..<videos.count)]
            return Post(
                id: UUID(),
                authorID: UUID(),
                mediaURL: videoURL,
                mediaKind: .video,
                caption: captions[i % captions.count],
                cigarID: CigarCatalog.all.randomElement()?.id,
                storeID: nil,
                createdAt: Date().addingTimeInterval(-Double(i) * 3600),
                cigarReactionCount: Int.random(in: 12...2400),
                commentCount: Int.random(in: 100...200),
                saveCount: Int.random(in: 0...400),
                viewCount: Int.random(in: 10_000...300_000),
                viewerHasReacted: false
            )
        }
    }
}

enum SampleAds {
    static func make(count: Int) -> [AdCreative] {
        let ads: [(name: String, headline: String, cta: String, video: String)] = [
            ("Brooklyn Cigar Lounge",
             "New OpusX arrivals — limited box pickup.",
             "Visit lounge",
             "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4"),
            ("Humidor NYC",
             "20% off your first online order this week.",
             "Shop now",
             "https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4"),
            ("Smoke & Oak",
             "Whiskey + cigar pairing night, Saturday 8pm.",
             "Reserve a seat",
             "https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/Jellyfish_720_10s_1MB.mp4"),
            ("Ash Social Club",
             "Members-only Padron 1926 tasting next Friday.",
             "Join the club",
             "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4"),
            ("Casa de Habano",
             "Authentic Cuban cigars, hand-rolled in-store.",
             "Find a location",
             "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4")
        ]
        return (0..<count).map { i in
            let ad = ads[i % ads.count]
            return AdCreative(
                id: UUID(),
                businessID: UUID(),
                businessName: ad.name,
                mediaURL: URL(string: ad.video)!,
                mediaKind: .video,
                headline: ad.headline,
                ctaLabel: ad.cta,
                ctaURL: nil
            )
        }
    }
}
