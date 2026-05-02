import SwiftUI

struct HomeView: View {
    @Environment(JellyfinAPI.self) private var api
    @State private var resumeItems: [MediaItem] = []
    @State private var recentMovies: [MediaItem] = []
    @State private var recentEpisodes: [MediaItem] = []
    @State private var selectedItem: MediaItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "111111").ignoresSafeArea()

                if resumeItems.isEmpty && recentMovies.isEmpty && recentEpisodes.isEmpty {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 60) {
                            if !resumeItems.isEmpty {
                                MediaRow(title: "Continue Watching", items: resumeItems) {
                                    selectedItem = $0
                                }
                            }
                            if !recentMovies.isEmpty {
                                MediaRow(title: "Recently Added Movies", items: recentMovies) {
                                    selectedItem = $0
                                }
                            }
                            if !recentEpisodes.isEmpty {
                                MediaRow(title: "Recently Added Episodes", items: recentEpisodes) {
                                    selectedItem = $0
                                }
                            }
                        }
                        .padding(.vertical, 60)
                        .padding(.horizontal, 70)
                    }
                }
            }
            .navigationTitle("Jelly")
        }
        .task { await load() }
        .fullScreenCover(item: $selectedItem) { item in
            PlayerView(item: item)
        }
    }

    private func load() async {
        async let r = try? api.fetchResumeItems()
        async let m = try? api.fetchRecentMovies()
        async let e = try? api.fetchRecentEpisodes()
        resumeItems = (await r) ?? []
        recentMovies = (await m) ?? []
        recentEpisodes = (await e) ?? []
    }
}
