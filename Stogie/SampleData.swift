import Foundation

// Placeholder content used while the For You feed is not yet wired
// to Supabase. Delete once the real fetch path is live.

enum SamplePosts {
    static func make(count: Int) -> [Post] {
        let captions = [
            "Sunday afternoon with a 1964 Anniversary.",
            "First OpusX of the year. Worth the wait.",
            "Padron 1926 pairs perfectly with this bourbon.",
            "New humidor, who dis.",
            "Friday night at the lounge.",
            "Ash game strong."
        ]
        return (0..<count).map { i in
            Post(
                id: UUID(),
                authorID: UUID(),
                mediaURL: URL(string: "https://example.com/placeholder.jpg")!,
                mediaKind: .photo,
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
        let ads: [(String, String, String)] = [
            ("Brooklyn Cigar Lounge", "New OpusX arrivals this week.", "Visit lounge"),
            ("Humidor NYC", "20% off your first online order.", "Shop now"),
            ("Smoke & Oak", "Whiskey + cigar pairing night, Saturday.", "Reserve seat"),
            ("Ash Social Club", "Members-only Padron tasting.", "Join club")
        ]
        return (0..<count).map { i in
            let ad = ads[i % ads.count]
            return AdCreative(
                id: UUID(),
                businessID: UUID(),
                businessName: ad.0,
                mediaURL: URL(string: "https://example.com/ad.jpg")!,
                mediaKind: .photo,
                headline: ad.1,
                ctaLabel: ad.2,
                ctaURL: nil
            )
        }
    }
}
