import SwiftUI

struct TVShowDetailView: View {
    let show: MediaItem
    @Environment(JellyfinAPI.self) private var api
    @State private var seasons: [MediaItem] = []
    @State private var selectedSeason: MediaItem?
    @State private var episodes: [MediaItem] = []
    @State private var selectedEpisode: MediaItem?
    @State private var isLoadingEpisodes = false

    var body: some View {
        ZStack {
            Color(hex: "111111").ignoresSafeArea()

            HStack(alignment: .top, spacing: 0) {
                // Season sidebar
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seasons")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 20)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(seasons) { season in
                                SeasonRow(season: season, isSelected: selectedSeason?.id == season.id)
                                    .onTapGesture {
                                        selectedSeason = season
                                        Task { await loadEpisodes(season) }
                                    }
                            }
                        }
                    }
                }
                .frame(width: 280)
                .padding(.top, 60)

                Divider()
                    .background(Color.white.opacity(0.1))

                // Episode list
                ScrollView {
                    if isLoadingEpisodes {
                        ProgressView().padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(episodes) { episode in
                                EpisodeRow(episode: episode, action: { selectedEpisode = episode })
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 60)
                    }
                }
            }
        }
        .navigationTitle(show.name)
        .task { await loadSeasons() }
        .fullScreenCover(item: $selectedEpisode) { episode in
            PlayerView(item: episode)
        }
    }

    private func loadSeasons() async {
        seasons = (try? await api.fetchSeasons(seriesId: show.id)) ?? []
        if let first = seasons.first {
            selectedSeason = first
            await loadEpisodes(first)
        }
    }

    private func loadEpisodes(_ season: MediaItem) async {
        isLoadingEpisodes = true
        episodes = (try? await api.fetchEpisodes(seriesId: show.id, seasonId: season.id)) ?? []
        isLoadingEpisodes = false
    }
}

struct SeasonRow: View {
    let season: MediaItem
    let isSelected: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        Text(season.name)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected || isFocused ? .white : .gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(isSelected ? Color.white.opacity(0.12) : (isFocused ? Color.white.opacity(0.08) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .focusable()
            .focused($isFocused)
            .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

struct EpisodeRow: View {
    let episode: MediaItem
    let action: () -> Void
    @Environment(JellyfinAPI.self) private var api
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                AsyncImage(url: api.imageURL(itemId: episode.id, type: "Primary", maxWidth: 300)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(Color.white.opacity(0.07))
                            .overlay { Image(systemName: "play.fill").foregroundStyle(.gray) }
                    }
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 6) {
                    if let ep = episode.indexNumber {
                        Text("Episode \(ep)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Text(episode.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let overview = episode.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                    }
                    if let progress = watchProgress {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.2)).frame(height: 3)
                                Capsule().fill(Color.white).frame(width: geo.size.width * progress, height: 3)
                            }
                        }
                        .frame(maxWidth: 300, maxHeight: 3)
                    }
                }

                Spacer()

                if episode.userData?.played == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green.opacity(0.8))
                        .font(.title3)
                }
            }
            .padding(16)
            .background(isFocused ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isFocused)
    }

    private var watchProgress: Double? {
        guard let pos = episode.userData?.playbackPositionTicks,
              let total = episode.runTimeTicks,
              total > 0, pos > 0 else { return nil }
        return min(1.0, Double(pos) / Double(total))
    }
}
