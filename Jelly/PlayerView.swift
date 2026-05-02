import SwiftUI
import AVKit

struct PlayerView: View {
    let item: MediaItem
    @Environment(JellyfinAPI.self) private var api
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var sessionId: String?
    @State private var progressTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(2)
            }
        }
        .task { await setup() }
        .onDisappear { teardown() }
    }

    private func setup() async {
        do {
            let info = try await api.fetchPlaybackInfo(itemId: item.id)
            guard let source = info.mediaSources.first,
                  let url = api.streamURL(from: source) else {
                dismiss()
                return
            }

            sessionId = info.playSessionId
            let avPlayer = AVPlayer(url: url)

            if let ticks = item.userData?.playbackPositionTicks, ticks > 0 {
                let seconds = Double(ticks) / 10_000_000
                avPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: 600),
                              toleranceBefore: .zero, toleranceAfter: .zero)
            }

            player = avPlayer
            avPlayer.play()

            if let sid = sessionId {
                await api.reportPlaybackStart(itemId: item.id, sessionId: sid)
            }

            startProgressReporting()
        } catch {
            dismiss()
        }
    }

    private func startProgressReporting() {
        progressTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, let sid = sessionId, let player else { break }
                let ticks = Int64(player.currentTime().seconds * 10_000_000)
                await api.reportProgress(itemId: item.id, sessionId: sid, ticks: ticks)
            }
        }
    }

    private func teardown() {
        progressTask?.cancel()
        guard let player, let sid = sessionId else { return }
        let ticks = Int64(player.currentTime().seconds * 10_000_000)
        player.pause()
        Task {
            await api.reportPlaybackStopped(itemId: item.id, sessionId: sid, ticks: ticks)
        }
    }
}
