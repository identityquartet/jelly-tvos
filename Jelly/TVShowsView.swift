import SwiftUI

struct TVShowsView: View {
    @Environment(JellyfinAPI.self) private var api
    @State private var shows: [MediaItem] = []
    @State private var isLoading = true
    @State private var selectedShow: MediaItem?

    let columns = [GridItem(.adaptive(minimum: 210), spacing: 24)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "111111").ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 40) {
                            ForEach(shows) { show in
                                PosterCard(item: show) { selectedShow = show }
                            }
                        }
                        .padding(.horizontal, 70)
                        .padding(.vertical, 60)
                    }
                }
            }
            .navigationTitle("TV Shows")
            .navigationDestination(item: $selectedShow) { show in
                TVShowDetailView(show: show)
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        shows = (try? await api.fetchTVShows()) ?? []
        isLoading = false
    }
}
