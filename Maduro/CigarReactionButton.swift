import SwiftUI

/// Cigar-shaped reaction button — replaces the heart/like.
/// Uses SF Symbol "flame.fill" as a placeholder until we ship a
/// custom cigar glyph in Assets.xcassets.
struct CigarReactionButton: View {
    let count: Int
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    // Cigar body (rounded capsule in tobacco brown)
                    Capsule()
                        .fill(isOn ? Color.orange : Color(red: 0.36, green: 0.21, blue: 0.09))
                        .frame(width: 34, height: 12)
                    // Ash tip
                    Circle()
                        .fill(isOn ? Color.yellow : Color.gray.opacity(0.7))
                        .frame(width: 10, height: 10)
                        .offset(x: -17)
                    // Ember
                    if isOn {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 4, height: 4)
                            .offset(x: -17)
                    }
                }
                .shadow(color: isOn ? .orange.opacity(0.6) : .clear, radius: 6)
                Text("\(count)")
                    .font(.caption2).bold()
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}
