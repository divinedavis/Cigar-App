import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Circle()
                        .fill(.brown.gradient)
                        .frame(width: 96, height: 96)
                        .overlay(Image(systemName: "person.fill").font(.largeTitle).foregroundStyle(.white))

                    HStack(spacing: 6) {
                        Text(session.currentUser?.displayName ?? "You")
                            .font(.title2).bold()
                        if session.currentUser?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.orange)
                        }
                    }

                    Text("@\(session.currentUser?.username ?? "stogie_user")")
                        .font(.subheadline).foregroundStyle(.secondary)

                    if session.currentUser?.accountType == .business {
                        Label("Business account", systemImage: "building.2.fill")
                            .font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.orange.opacity(0.2), in: .capsule)
                    }

                    HStack(spacing: 32) {
                        stat("0", "Posts")
                        stat("0", "Followers")
                        stat("0", "Following")
                    }
                    .padding(.vertical, 12)

                    Button("Sign out") { session.signOut() }
                        .foregroundStyle(.red)
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
