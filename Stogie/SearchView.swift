import SwiftUI

/// Browse / search the cigar catalog. Tap a row to open the cigar's
/// review detail page.
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var selected: Cigar?

    private var filtered: [Cigar] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return CigarCatalog.all }
        return CigarCatalog.all.filter { c in
            c.brand.lowercased().contains(q)
                || c.line.lowercased().contains(q)
                || (c.vitola?.lowercased().contains(q) ?? false)
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

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { cigar in
                            Button { selected = cigar } label: {
                                CigarRow(cigar: cigar)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
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
            .navigationDestination(item: $selected) { cigar in
                CigarDetailView(cigar: cigar)
            }
        }
        .preferredColorScheme(.dark)
    }
}

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
