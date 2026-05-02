import SwiftUI

struct PosterCard: View {
    let item: MediaItem
    let action: () -> Void
    @Environment(JellyfinAPI.self) private var api
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                AsyncImage(url: api.imageURL(itemId: item.id, maxWidth: 400)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .overlay {
                                Image(systemName: item.type == "Series" ? "tv" : "film")
                                    .foregroundStyle(.white.opacity(0.25))
                                    .font(.system(size: 40))
                            }
                    }
                }
                .frame(width: 200, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let progress = watchProgress {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2)).frame(height: 3)
                            Capsule().fill(Color.white).frame(width: geo.size.width * progress, height: 3)
                        }
                    }
                    .frame(width: 200, height: 3)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let series = item.seriesName {
                        Text(series)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(isFocused ? 0.9 : 0), lineWidth: 3)
                .frame(width: 200, height: 300)
                .offset(y: -13)
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    private var watchProgress: Double? {
        guard let pos = item.userData?.playbackPositionTicks,
              let total = item.runTimeTicks,
              total > 0, pos > 0 else { return nil }
        return min(1.0, Double(pos) / Double(total))
    }
}
