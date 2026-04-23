import SwiftUI

@main
struct StogieApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        if session.currentUser == nil {
            SplashView()
        } else {
            MainTabView()
        }
    }
}
