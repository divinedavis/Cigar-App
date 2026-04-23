import SwiftUI

struct MainTabView: View {
    @State private var selection: Tab = .forYou
    @State private var isPresentingCreate = false

    enum Tab: Hashable { case forYou, create, profile }

    var body: some View {
        TabView(selection: $selection) {
            ForYouView()
                .tabItem { Label("For You", systemImage: "house.fill") }
                .tag(Tab.forYou)

            Color.clear
                .tabItem { Label("Post", systemImage: "plus.square.fill") }
                .tag(Tab.create)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(.orange)
        .onChange(of: selection) { _, new in
            if new == .create {
                isPresentingCreate = true
                selection = .forYou
            }
        }
        .fullScreenCover(isPresented: $isPresentingCreate) {
            CreatePostView()
        }
    }
}
