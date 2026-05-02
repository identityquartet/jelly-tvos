import SwiftUI

struct MediaRow: View {
    let title: String
    let items: [MediaItem]
    let onSelect: (MediaItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(items) { item in
                        PosterCard(item: item, action: { onSelect(item) })
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}
