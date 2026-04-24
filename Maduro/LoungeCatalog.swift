import Foundation

/// A cigar lounge the user could visit. Real data will come from Apple
/// Maps `MKLocalSearch` once nearby-search is wired; for now we ship a
/// static list of well-known spots so the Search feed has something to
/// render.
struct Lounge: Identifiable, Hashable {
    let id: UUID
    let name: String
    let neighborhood: String
    let rating: Double
    let reviewCount: Int

    /// Up to 30 deterministic stock photos keyed by the lounge id.
    var galleryURLs: [URL] {
        (0..<25).compactMap { offset in
            URL(string: "https://picsum.photos/seed/\(id.uuidString.prefix(8))-\(offset)/1200/800")
        }
    }

    /// Query string handed to Apple Maps when the location pill is tapped.
    var mapsQuery: String { "\(name), \(neighborhood)" }

    /// Is this a guest-favorite lounge? (Top slice of the list for now.)
    var isGuestFavorite: Bool { rating >= 4.6 }
}

enum LoungeCatalog {
    static let nearby: [Lounge] = [
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000001")!,
               name: "Barclay Rex",            neighborhood: "FiDi, Manhattan",     rating: 4.7, reviewCount: 412),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000002")!,
               name: "Carnegie Club",          neighborhood: "Midtown, Manhattan",  rating: 4.8, reviewCount: 1_209),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000003")!,
               name: "De La Concha",           neighborhood: "Midtown, Manhattan",  rating: 4.6, reviewCount: 634),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000004")!,
               name: "Merchants Cigar Bar",    neighborhood: "Park Slope, Brooklyn", rating: 4.5, reviewCount: 287),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000005")!,
               name: "Velvet Cigar Lounge",    neighborhood: "East Village",         rating: 4.4, reviewCount: 198),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000006")!,
               name: "Club Macanudo",          neighborhood: "Upper East Side",      rating: 4.6, reviewCount: 521),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000007")!,
               name: "Ashton Cigar Bar",       neighborhood: "Rittenhouse, Philly",  rating: 4.7, reviewCount: 345),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000008")!,
               name: "Casa de Montecristo",    neighborhood: "Edison, NJ",           rating: 4.5, reviewCount: 276),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000009")!,
               name: "Soho Cigar Bar",         neighborhood: "SoHo, Manhattan",      rating: 4.3, reviewCount: 452),
        Lounge(id: UUID(uuidString: "11111111-0001-0000-0000-000000000010")!,
               name: "Grand Havana Room",      neighborhood: "Midtown, Manhattan",   rating: 4.9, reviewCount: 812),
    ]
}
