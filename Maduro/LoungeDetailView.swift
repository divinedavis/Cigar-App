import SwiftUI
import UIKit

/// Airbnb-style detail page for a cigar lounge — hero photo carousel,
/// a stats strip (rating · guest favorite · reviews), and a tappable
/// location that launches Apple Maps with driving directions.
struct LoungeDetailView: View {
    let lounge: Lounge

    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex: Int = 0
    @State private var isFavorited = false

    private var images: [URL] { lounge.galleryURLs }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    gallery
                    content
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color(red: 0.08, green: 0.05, blue: 0.03))
                        )
                        .offset(y: -24)
                        .padding(.bottom, -24)
                }
            }

            floatingToolbar
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    // MARK: Gallery

    private var gallery: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $pageIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                    GalleryImage(url: url)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 420)

            Text("\(pageIndex + 1) / \(images.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.55), in: .capsule)
                .padding(.trailing, 18)
                .padding(.bottom, 44)
        }
    }

    private var floatingToolbar: some View {
        HStack {
            circularButton(systemName: "chevron.left") { dismiss() }
            Spacer()
            HStack(spacing: 10) {
                circularButton(systemName: "square.and.arrow.up") { }
                circularButton(systemName: isFavorited ? "heart.fill" : "heart",
                               tint: isFavorited ? .red : .white) {
                    isFavorited.toggle()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func circularButton(systemName: String,
                                tint: Color = .white,
                                action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: .circle)
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
        }
    }

    // MARK: Content card

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(lounge.name)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Button { openInMaps() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline)
                    Text(lounge.neighborhood)
                        .font(.subheadline.weight(.semibold))
                        .underline()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white.opacity(0.85))
            }

            statsStrip

            Divider().background(.white.opacity(0.12))

            aboutRow
        }
        .padding(.horizontal, 22)
        .padding(.top, 28)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statColumn {
                Text(String(format: "%.2f", lounge.rating))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < Int(lounge.rating.rounded()) ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Divider().frame(height: 44).background(.white.opacity(0.15))

            statColumn {
                HStack(spacing: 4) {
                    Image(systemName: "laurel.leading")
                        .font(.footnote)
                        .foregroundStyle(.orange.opacity(0.9))
                    Text("Guest\nfavorite")
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Image(systemName: "laurel.trailing")
                        .font(.footnote)
                        .foregroundStyle(.orange.opacity(0.9))
                }
                .opacity(lounge.isGuestFavorite ? 1.0 : 0.35)
            }

            Divider().frame(height: 44).background(.white.opacity(0.15))

            statColumn {
                Text("\(lounge.reviewCount)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("Reviews")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05), in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func statColumn<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 6) {
            content()
        }
        .frame(maxWidth: .infinity)
    }

    private var aboutRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this lounge")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Walk-in humidor, full bar, and a classic leather-chair lounge. Members-only back room for private tastings and cutter service on request.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(3)
        }
    }

    // MARK: Actions

    private func openInMaps() {
        let query = lounge.mapsQuery
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // `dirflg=d` requests driving directions; `?daddr=` is the destination.
        if let url = URL(string: "http://maps.apple.com/?daddr=\(query)&dirflg=d"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Gallery image

private struct GalleryImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                LinearGradient(
                    colors: [Color(red: 0.32, green: 0.18, blue: 0.08),
                             Color(red: 0.12, green: 0.06, blue: 0.02)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.6))
                )
            }
        }
        .clipped()
    }
}
