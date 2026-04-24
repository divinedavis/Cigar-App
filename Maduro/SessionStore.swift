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
        didSet { persistCurrent() }
    }
    @Published var isSubscribed: Bool = false

    private let currentKey = "maduro.currentUser.v1"
    private let directoryKey = "maduro.identityDirectory.v1"

    /// Maps "<method>:<identifier>" -> previously-created AppUser, so a
    /// returning Apple / email user is recognized after sign-out instead of
    /// being pushed through the age-gate sign-up flow again.
    private var directory: [String: AppUser] = [:]

    init() {
        currentUser = loadPersistedCurrent()
        directory = loadPersistedDirectory()
    }

    func signIn(as user: AppUser) {
        currentUser = user
    }

    func signOut() {
        currentUser = nil
    }

    /// Returns a previously-registered user for the given sign-in method +
    /// identifier (e.g. Apple's stable user ID or a normalized email).
    func lookup(method: String, identifier: String) -> AppUser? {
        directory[Self.key(method: method, identifier: identifier)]
    }

    /// Associates a signed-up user with the sign-in method + identifier they
    /// used so they're recognized on future log-ins.
    func register(method: String, identifier: String, user: AppUser) {
        directory[Self.key(method: method, identifier: identifier)] = user
        persistDirectory()
    }

    private static func key(method: String, identifier: String) -> String {
        "\(method):\(identifier)"
    }

    private func persistCurrent() {
        let defaults = UserDefaults.standard
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: currentKey)
        } else {
            defaults.removeObject(forKey: currentKey)
        }
    }

    private func persistDirectory() {
        guard let data = try? JSONEncoder().encode(directory) else { return }
        UserDefaults.standard.set(data, forKey: directoryKey)
    }

    private func loadPersistedCurrent() -> AppUser? {
        guard let data = UserDefaults.standard.data(forKey: currentKey) else { return nil }
        return try? JSONDecoder().decode(AppUser.self, from: data)
    }

    private func loadPersistedDirectory() -> [String: AppUser] {
        guard let data = UserDefaults.standard.data(forKey: directoryKey) else { return [:] }
        return (try? JSONDecoder().decode([String: AppUser].self, from: data)) ?? [:]
    }
}
