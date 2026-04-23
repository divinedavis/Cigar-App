import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isSubscribed: Bool = false

    func signIn(as user: AppUser) {
        currentUser = user
    }

    func signOut() {
        currentUser = nil
    }
}
