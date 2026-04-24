import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    title

                    if let user = session.currentUser {
                        ProfileCard(user: user)

                        FactsList(user: user)

                        bio(user)

                        membershipChip

                        actions
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [.black, Color(red: 0.10, green: 0.06, blue: 0.03)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button { showShareSheet = true } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button {} label: {
                            Image(systemName: "heart")
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var title: some View {
        Text(session.currentUser.map { "Meet \($0.displayName)" } ?? "Your profile")
            .font(.largeTitle).bold()
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bio(_ user: AppUser) -> some View {
        let body = user.bio.isEmpty
            ? "Just a humidor, a draw, and good company. Looking for the next perfect smoke."
            : user.bio
        return Text(body)
            .font(.body)
            .foregroundStyle(.white.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private var membershipChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "diamond.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
            Text(session.isSubscribed
                 ? "Maduro Premium · ad-free"
                 : "Free account · ads every 4–10 posts")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 12))
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if !session.isSubscribed {
                Button {
                    session.isSubscribed = true
                } label: {
                    Text("Go ad-free with Maduro Premium")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(Color.orange, in: .rect(cornerRadius: 12))
            }

            Button {
                session.signOut()
            } label: {
                Text("Sign out")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.red.opacity(0.6), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Card

private struct ProfileCard: View {
    let user: AppUser

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(.brown.gradient)
                        .frame(width: 96, height: 96)
                        .overlay(
                            Text(initials)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        )
                    if user.isVerified || user.accountType == .business {
                        Circle()
                            .fill(.orange)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 4, y: 4)
                    }
                }

                Text(user.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if user.accountType == .business {
                    Label("Business", systemImage: "rosette")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                } else if user.isVerified {
                    Label("21+ verified", systemImage: "checkmark.seal.fill")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                } else {
                    Text("@\(user.username)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 0) {
                StatRow(value: "0", label: "Posts")
                Divider().background(.white.opacity(0.15))
                StatRow(value: "0", label: "Reactions")
                Divider().background(.white.opacity(0.15))
                StatRow(value: "\(yearsOnMaduro)", label: yearsOnMaduro == 1 ? "Year on Maduro" : "Years on Maduro")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var initials: String {
        let parts = user.displayName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    private var yearsOnMaduro: Int {
        // Placeholder until we have a createdAt on AppUser. Always 1 for new accounts.
        1
    }
}

private struct StatRow: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }
}

// MARK: - Facts list

private struct FactsList: View {
    let user: AppUser

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            FactRow(icon: "briefcase",
                    text: "My work: \(work)")
            FactRow(icon: "clock",
                    text: "Smoking since: \(smokingSince)")
            FactRow(icon: "lightbulb",
                    text: "Favorite: \(favoriteCigar)")
            FactRow(icon: "fork.knife.circle",
                    text: "I pair with: Bourbon, neat")
            FactRow(icon: "mappin.and.ellipse",
                    text: "Home lounge: Brooklyn Cigar Lounge")
            FactRow(icon: "calendar",
                    text: "Member since: \(memberSince)")
        }
        .padding(.top, 8)
    }

    private var work: String {
        user.accountType == .business ? "Cigar lounge owner" : "Cigar enthusiast"
    }

    private var smokingSince: String {
        // Roughly half their adult life — a friendly default until we collect this.
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: user.dateOfBirth, to: Date()).year ?? 21
        let years = max(1, age / 4)
        return "\(years) year\(years == 1 ? "" : "s")"
    }

    private var favoriteCigar: String {
        // Deterministic pick so the same user always sees the same favorite.
        let seed = abs(user.id.hashValue)
        let cigar = CigarCatalog.all[seed % CigarCatalog.all.count]
        return cigar.displayName
    }

    private var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

private struct FactRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 26, height: 26)
                .foregroundStyle(.orange)
            Text(text)
                .font(.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
