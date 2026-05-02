import SwiftUI

struct RootView: View {
    @Environment(JellyfinAPI.self) private var api

    var body: some View {
        if api.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
