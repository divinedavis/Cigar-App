import Foundation
import SwiftUI

/// Stub review model + deterministic mock data per Cigar.
///
/// Each Cigar gets a stable mock rating, review count, sub-stats, and
/// review list seeded from its UUID hash, so the same cigar always
/// surfaces the same numbers without needing a backend yet.
struct CigarReview: Identifiable {
    let id = UUID()
    let username: String
    let location: String
    let date: String
    let rating: Int       // 1 - 5
    let body: String
}

struct CigarRatingBreakdown {
    let overall: Double           // 0.0 - 5.0
    let totalReviews: Int
    let star5: Int
    let star4: Int
    let star3: Int
    let star2: Int
    let star1: Int
    let draw: Double              // 0.0 - 5.0
    let flavor: Double            // 0.0 - 5.0
}

extension Cigar {
    /// Stable seed in [0, 1000) derived from the Cigar's UUID.
    private var seed: Int {
        abs(id.uuidString.hashValue) % 1000
    }

    var mockRating: Double {
        let raw = 3.8 + Double(seed % 12) / 10.0    // 3.8 - 4.9
        return (raw * 100).rounded() / 100
    }

    var mockReviewCount: Int {
        18 + (seed % 480)
    }

    var ratingBreakdown: CigarRatingBreakdown {
        let total = mockReviewCount
        let s5 = Int(Double(total) * (0.55 + Double(seed % 15) / 100))
        let s4 = Int(Double(total) * (0.20 + Double(seed % 10) / 100))
        let s3 = Int(Double(total) * 0.10)
        let s2 = Int(Double(total) * 0.05)
        let s1 = max(0, total - s5 - s4 - s3 - s2)
        return CigarRatingBreakdown(
            overall: mockRating,
            totalReviews: total,
            star5: s5, star4: s4, star3: s3, star2: s2, star1: s1,
            draw: max(3.5, mockRating - Double(seed % 4) / 10.0),
            flavor: min(5.0, mockRating + Double(seed % 3) / 10.0)
        )
    }

    var mockReviews: [CigarReview] {
        let usernames = [
            "padron_pete", "humidor_hannah", "ash_axel",
            "brooklyn_bryant", "nicaragua_nadia", "havana_henry",
            "tampa_tess", "maduro_marco", "cohiba_chloe", "rocky_rob"
        ]
        let locations = [
            "Brooklyn, NY", "Miami, FL", "Tampa, FL",
            "Chicago, IL", "Austin, TX", "Los Angeles, CA",
            "Boston, MA", "Atlanta, GA", "Philadelphia, PA"
        ]
        let dates = [
            "March 2026", "February 2026", "January 2026",
            "December 2025", "November 2025", "October 2025"
        ]
        let bodies = [
            "Perfect draw, even burn, cool finish. Couldn't ask for more — already ordered another box.",
            "Spicy first third, leathery middle, finishes with cocoa and a touch of cedar. Two-hour smoke, easy.",
            "Construction is on point. The ash held three inches before I tapped it. Worth every dollar.",
            "Paired this with a Lagavulin 16 — heaven. The wrapper is oily, the draw is smooth, the flavor stays consistent.",
            "Honestly overrated for the price. Decent smoke but I've had better in this range.",
            "Maduro fans will love this one. Sweet and rich with notes of espresso and dark chocolate.",
            "First third is a slow start but it really opens up. Patience pays off with this stick.",
            "Great morning smoke with coffee. Mild enough to wake up to, complex enough to stay interesting.",
            "If you can find these, grab a box. They go fast and they're only getting harder to source."
        ]

        return (0..<6).map { i in
            let userIdx = (seed + i * 3) % usernames.count
            let locIdx = (seed + i * 5) % locations.count
            let dateIdx = (seed + i * 2) % dates.count
            let bodyIdx = (seed + i * 7) % bodies.count
            let rating = i == 4 ? 3 : (i == 5 ? 4 : 5)
            return CigarReview(
                username: usernames[userIdx],
                location: locations[locIdx],
                date: dates[dateIdx],
                rating: rating,
                body: bodies[bodyIdx]
            )
        }
    }
}
