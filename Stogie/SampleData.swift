import Foundation

// Placeholder content used while the For You feed is not yet wired
// to Supabase. Delete once the real fetch path is live.
//
// Videos come from Google's public "gtv-videos-bucket" sample set
// — widely used in iOS sample code and stable. Photos come from
// picsum.photos seeded so each post gets a stable image.

private enum SampleMedia {
    static let videos: [URL] = [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
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
        return (0..<count).map { i in
            // Roughly half videos, half photos — interleaved.
            let isVideo = i % 2 == 0
            let mediaURL: URL = isVideo
                ? SampleMedia.videos[i % SampleMedia.videos.count]
                : SampleMedia.photo(seed: "stogie-post-\(i)")
            return Post(
                id: UUID(),
                authorID: UUID(),
                mediaURL: mediaURL,
                mediaKind: isVideo ? .video : .photo,
                caption: captions[i % captions.count],
                cigarID: CigarCatalog.all.randomElement()?.id,
                storeID: nil,
                createdAt: Date().addingTimeInterval(-Double(i) * 3600),
                cigarReactionCount: Int.random(in: 12...2400),
                commentCount: Int.random(in: 0...180),
                saveCount: Int.random(in: 0...400),
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
             "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4"),
            ("Humidor NYC",
             "20% off your first online order this week.",
             "Shop now",
             "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4"),
            ("Smoke & Oak",
             "Whiskey + cigar pairing night, Saturday 8pm.",
             "Reserve a seat",
             "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4"),
            ("Ash Social Club",
             "Members-only Padron 1926 tasting next Friday.",
             "Join the club",
             "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"),
            ("Casa de Habano",
             "Authentic Cuban cigars, hand-rolled in-store.",
             "Find a location",
             "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4")
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
