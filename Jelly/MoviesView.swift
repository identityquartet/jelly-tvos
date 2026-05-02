import SwiftUI

struct MoviesView: View {
    @Environment(JellyfinAPI.self) private var api
    @State private var movies: [MediaItem] = []
    @State private var isLoading = true
    @State private var selectedMovie: MediaItem?

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
                            ForEach(movies) { movie in
                                PosterCard(item: movie) { selectedMovie = movie }
                            }
                        }
                        .padding(.horizontal, 70)
                        .padding(.vertical, 60)
                    }
                }
            }
            .navigationTitle("Movies")
        }
        .task { await load() }
        .fullScreenCover(item: $selectedMovie) { movie in
            PlayerView(item: movie)
        }
    }

    private func load() async {
        isLoading = true
        movies = (try? await api.fetchMovies()) ?? []
        isLoading = false
    }
}
