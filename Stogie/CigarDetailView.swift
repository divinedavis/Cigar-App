import SwiftUI

/// Cigar review page modeled after Airbnb's "Guest favorite" review
/// screen — laurel wreaths around a big rating, a "Smoker favorite"
/// designation, a 5-bar distribution, two sub-stats, then the review
/// list with a search input.
struct CigarDetailView: View {
    let cigar: Cigar
    @State private var reviewQuery: String = ""
    @State private var sort: ReviewSort = .mostRelevant

    enum ReviewSort: String, CaseIterable, Identifiable {
        case mostRelevant = "Most relevant"
        case newest       = "Newest"
        case highest      = "Highest rated"
        case lowest       = "Lowest rated"
        var id: String { rawValue }
    }

    private var breakdown: CigarRatingBreakdown { cigar.ratingBreakdown }

    private var filteredReviews: [CigarReview] {
        let q = reviewQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let base = q.isEmpty
            ? cigar.mockReviews
            : cigar.mockReviews.filter { $0.body.lowercased().contains(q) }
        switch sort {
        case .mostRelevant: return base
        case .newest:       return base
        case .highest:      return base.sorted { $0.rating > $1.rating }
        case .lowest:       return base.sorted { $0.rating < $1.rating }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.10, green: 0.06, blue: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    laurelHero
                    cigarTitle
                    statsRow
                    Divider().background(.white.opacity(0.15))
                    reviewsHeader
                    searchBar
                    reviewsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black.opacity(0.4), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Hero

    private var laurelHero: some View {
        HStack(spacing: 12) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.orange)

            Text(String(format: "%.2f", breakdown.overall))
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(.white)

            Image(systemName: "laurel.trailing")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.orange)
        }
        .padding(.top, 4)
    }

    private var cigarTitle: some View {
        VStack(spacing: 6) {
            Text("Smoker favorite")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("\(cigar.brand) \(cigar.line)\(cigar.vitola.map { " — \($0)" } ?? "")")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Text("This cigar is in the **top \(topPercent)%** of Stogie's catalog based on ratings, reviews, and pairings.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
    }

    private var topPercent: Int {
        let pct = Int((5.0 - breakdown.overall) * 12)
        return max(2, min(pct, 25))
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            distributionColumn
            divider
            subStat(label: "Draw", value: breakdown.draw, icon: "wind")
            divider
            subStat(label: "Flavor", value: breakdown.flavor, icon: "leaf.fill")
        }
        .padding(.vertical, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(width: 1, height: 110)
            .padding(.horizontal, 8)
    }

    private var distributionColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Overall rating")
                .font(.caption.bold())
                .foregroundStyle(.white)
            ratingBar(stars: 5, count: breakdown.star5)
            ratingBar(stars: 4, count: breakdown.star4)
            ratingBar(stars: 3, count: breakdown.star3)
            ratingBar(stars: 2, count: breakdown.star2)
            ratingBar(stars: 1, count: breakdown.star1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ratingBar(stars: Int, count: Int) -> some View {
        let total = max(1, breakdown.totalReviews)
        let fraction = Double(count) / Double(total)
        return HStack(spacing: 6) {
            Text("\(stars)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 10, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))
                    Capsule()
                        .fill(.white)
                        .frame(width: max(2, geo.size.width * fraction))
                }
            }
            .frame(height: 4)
        }
    }

    private func subStat(label: String, value: Double, icon: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.white)
            Text(String(format: "%.1f", value))
                .font(.title2.bold())
                .foregroundStyle(.white)
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: Reviews list

    private var reviewsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(breakdown.totalReviews) reviews")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Learn how reviews work")
                    .font(.caption)
                    .underline()
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(ReviewSort.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(sort.rawValue)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    Capsule().stroke(.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.6))
            TextField("",
                      text: $reviewQuery,
                      prompt: Text("Search reviews").foregroundStyle(.white.opacity(0.5)))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.06), in: .capsule)
        .overlay(
            Capsule().stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var reviewsList: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(filteredReviews) { review in
                ReviewRow(review: review)
            }
            if filteredReviews.isEmpty {
                Text("No reviews match \"\(reviewQuery)\".")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
    }
}

private struct ReviewRow: View {
    let review: CigarReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(.brown.gradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(review.username.prefix(1)).uppercased())
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("@\(review.username)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(review.location)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
            }

            HStack(spacing: 8) {
                StarRow(rating: review.rating)
                Text("·")
                    .foregroundStyle(.white.opacity(0.5))
                Text(review.date)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("·")
                    .foregroundStyle(.white.opacity(0.5))
                Text("Smoked one")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(review.body)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StarRow: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}
