import SwiftUI

@main
struct JellyApp: App {
    @State private var api = JellyfinAPI()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(api)
        }
    }
}
