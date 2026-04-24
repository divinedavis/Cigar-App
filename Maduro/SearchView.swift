import SwiftUI

/// Airbnb-style discovery feed: horizontal carousels for popular cigars
/// and nearby lounges when the query is empty, collapsing into a
/// vertical filter list once the user starts typing.
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var selectedCigar: Cigar?
    @State private var selectedLounge: Lounge?

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var popularCigars: [Cigar] {
        // Top 10 by mockRating so "popular" is deterministic and non-empty.
        CigarCatalog.all
            .sorted { $0.mockRating > $1.mockRating }
            .prefix(10)
            .map { $0 }
    }

    private var filteredCigars: [Cigar] {
        guard !trimmedQuery.isEmpty else { return [] }
        return CigarCatalog.all.filter { c in
            c.brand.lowercased().contains(trimmedQuery)
                || c.line.lowercased().contains(trimmedQuery)
                || (c.vitola?.lowercased().contains(trimmedQuery) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.black, Color(red: 0.10, green: 0.06, blue: 0.03)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                if trimmedQuery.isEmpty {
                    discoveryContent
                } else {
                    resultsList
                }
            }
            .searchable(text: $query, prompt: "Search cigars by brand, line, or vitola")
            .navigationTitle("Cigars")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(.orange)
                }
            }
            .toolbarBackground(.black.opacity(0.4), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedCigar) { cigar in
                CigarDetailView(cigar: cigar)
            }
            .navigationDestination(item: $selectedLounge) { lounge in
                LoungeDetailView(lounge: lounge)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Discovery

    private var discoveryContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "Find popular cigars") {
                    horizontalRow(items: popularCigars) { cigar in
                        Button { selectedCigar = cigar } label: {
                            CigarPosterCard(cigar: cigar)
                        }
                        .buttonStyle(.plain)
                    }
                }

                section(title: "Cigar lounges near you") {
                    horizontalRow(items: LoungeCatalog.nearby) { lounge in
                        Button { selectedLounge = lounge } label: {
                            LoungePosterCard(lounge: lounge)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)

            content()
        }
    }

    @ViewBuilder
    private func horizontalRow<Item: Identifiable, Card: View>(
        items: [Item],
        @ViewBuilder card: @escaping (Item) -> Card
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(items) { item in
                    card(item)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Filtered results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredCigars) { cigar in
                    Button { selectedCigar = cigar } label: {
                        CigarRow(cigar: cigar)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Cards

private struct CigarPosterCard: View {
    let cigar: Cigar

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PosterImage(seed: cigar.id.uuidString, topic: "cigar")
                .frame(width: 220, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(cigar.brand) · \(cigar.line)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", cigar.mockRating))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("· \(cigar.mockReviewCount) reviews")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
        }
        .frame(width: 220, alignment: .leading)
    }
}

private struct LoungePosterCard: View {
    let lounge: Lounge

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PosterImage(seed: lounge.id.uuidString, topic: "lounge")
                .frame(width: 220, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(lounge.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", lounge.rating))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("· \(lounge.neighborhood)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
        }
        .frame(width: 220, alignment: .leading)
    }
}

/// Dummy image for prototype cards. Loads a deterministic random photo
/// from picsum.photos seeded by the item ID, with a warm gradient
/// fallback while it loads or if the network is unavailable.
private struct PosterImage: View {
    let seed: String
    let topic: String

    private var url: URL? {
        URL(string: "https://picsum.photos/seed/\(seed)/640/760")
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                fallbackGradient
                    .overlay(
                        Image(systemName: topic == "lounge" ? "sparkles" : "flame.fill")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(.white.opacity(0.75))
                    )
            }
        }
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.32, green: 0.18, blue: 0.08),
                Color(red: 0.14, green: 0.08, blue: 0.04),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Fallback row used when the user is actively searching.

private struct CigarRow: View {
    let cigar: Cigar

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.brown.gradient)
                    .frame(width: 56, height: 56)
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(cigar.brand)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                Text(cigar.line)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let vitola = cigar.vitola {
                    Text(vitola)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.2f", cigar.mockRating))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Text("\(cigar.mockReviewCount) reviews")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(14)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}
