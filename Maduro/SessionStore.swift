import Foundation
import SwiftUI

/// Holds the signed-in user for the lifetime of the app.
///
/// Persists the stub user to UserDefaults so cold starts don't sign
/// you out. When real Supabase auth is wired the Supabase SDK takes
/// over session persistence (keychain) and this UserDefaults shim
/// goes away.
@MainActor
final class SessionStore: ObservableObject {
    @Published var currentUser: AppUser? {
        didSet { persist() }
    }
    @Published var isSubscribed: Bool = false

    private let storageKey = "maduro.currentUser.v1"

    init() {
        currentUser = loadPersisted()
    }

    func signIn(as user: AppUser) {
        currentUser = user
    }

    func signOut() {
        currentUser = nil
    }

    private func persist() {
        let defaults = UserDefaults.standard
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: storageKey)
        } else {
            defaults.removeObject(forKey: storageKey)
        }
    }

    private func loadPersisted() -> AppUser? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AppUser.self, from: data)
    }
}
