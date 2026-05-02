import Foundation
import Observation

@Observable
class JellyfinAPI {
    var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    var token: String?
    var userId: String?
    var username: String?
    var isAuthenticated: Bool { token != nil && userId != nil }

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "http://192.168.8.117:8093"
        self.token = KeychainManager.loadToken()
        self.userId = KeychainManager.loadUserId()
        self.username = KeychainManager.loadUsername()
    }

    func authenticate(username: String, password: String) async throws {
        let url = URL(string: "\(serverURL)/Users/AuthenticateByName")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(embyAuth(), forHTTPHeaderField: "X-Emby-Authorization")
        req.httpBody = try JSONEncoder().encode(["Username": username, "Pw": password])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.token = auth.accessToken
        self.userId = auth.user.id
        self.username = auth.user.name
        KeychainManager.save(token: auth.accessToken, userId: auth.user.id, username: auth.user.name)
    }

    func signOut() {
        token = nil; userId = nil; username = nil
        KeychainManager.clear()
    }

    // MARK: - Library

    func fetchResumeItems() async throws -> [MediaItem] {
        guard let userId else { return [] }
        return try await getItems("/Users/\(userId)/Items/Resume?Limit=12&Fields=Overview,UserData,PrimaryImageAspectRatio&ImageTypeLimit=1&EnableImageTypes=Primary,Thumb")
    }

    func fetchRecentMovies() async throws -> [MediaItem] {
        guard let userId else { return [] }
        return try await getArray("/Users/\(userId)/Items/Latest?Limit=12&IncludeItemTypes=Movie&Fields=Overview,UserData,PrimaryImageAspectRatio&ImageTypeLimit=1&EnableImageTypes=Primary")
    }

    func fetchRecentEpisodes() async throws -> [MediaItem] {
        guard let userId else { return [] }
        return try await getArray("/Users/\(userId)/Items/Latest?Limit=12&IncludeItemTypes=Episode&Fields=Overview,UserData,PrimaryImageAspectRatio,SeriesName,SeriesId&ImageTypeLimit=1&EnableImageTypes=Primary,Thumb")
    }

    func fetchMovies() async throws -> [MediaItem] {
        guard let userId else { return [] }
        return try await getItems("/Users/\(userId)/Items?IncludeItemTypes=Movie&Recursive=true&SortBy=SortName&SortOrder=Ascending&Fields=Overview,UserData,PrimaryImageAspectRatio&ImageTypeLimit=1&EnableImageTypes=Primary&Limit=1000")
    }

    func fetchTVShows() async throws -> [MediaItem] {
        guard let userId else { return [] }
        return try await getItems("/Users/\(userId)/Items?IncludeItemTypes=Series&Recursive=true&SortBy=SortName&SortOrder=Ascending&Fields=Overview,UserData,PrimaryImageAspectRatio&ImageTypeLimit=1&EnableImageTypes=Primary&Limit=1000")
    }

    func fetchSeasons(seriesId: String) async throws -> [MediaItem] {
        guard let userId else { return [] }
        return try await getItems("/Shows/\(seriesId)/Seasons?userId=\(userId)&Fields=Overview,UserData,PrimaryImageAspectRatio")
    }

    func fetchEpisodes(seriesId: String, seasonId: String) async throws -> [MediaItem] {
        guard let userId else { return [] }
        return try await getItems("/Shows/\(seriesId)/Episodes?SeasonId=\(seasonId)&userId=\(userId)&Fields=Overview,UserData,PrimaryImageAspectRatio&ImageTypeLimit=1&EnableImageTypes=Primary,Thumb")
    }

    // MARK: - Playback

    func fetchPlaybackInfo(itemId: String) async throws -> PlaybackInfoResponse {
        guard let userId else { throw URLError(.userAuthenticationRequired) }
        let url = URL(string: "\(serverURL)/Items/\(itemId)/PlaybackInfo")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuth(to: &req)
        req.httpBody = try JSONSerialization.data(withJSONObject: deviceProfile(userId: userId))
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(PlaybackInfoResponse.self, from: data)
    }

    func reportPlaybackStart(itemId: String, sessionId: String) async {
        await post("/Sessions/Playing", body: [
            "ItemId": itemId, "PlaySessionId": sessionId,
            "UserId": userId ?? "", "CanSeek": true, "PlayMethod": "Transcode"
        ])
    }

    func reportProgress(itemId: String, sessionId: String, ticks: Int64) async {
        await post("/Sessions/Playing/Progress", body: [
            "ItemId": itemId, "PlaySessionId": sessionId,
            "UserId": userId ?? "", "PositionTicks": ticks,
            "CanSeek": true, "PlayMethod": "Transcode"
        ])
    }

    func reportPlaybackStopped(itemId: String, sessionId: String, ticks: Int64) async {
        await post("/Sessions/Playing/Stopped", body: [
            "ItemId": itemId, "PlaySessionId": sessionId,
            "UserId": userId ?? "", "PositionTicks": ticks
        ])
    }

    // MARK: - Helpers

    func imageURL(itemId: String, type: String = "Primary", maxWidth: Int = 400) -> URL? {
        URL(string: "\(serverURL)/Items/\(itemId)/Images/\(type)?maxWidth=\(maxWidth)")
    }

    func streamURL(from source: MediaSource) -> URL? {
        if let path = source.transcodingUrl { return URL(string: "\(serverURL)\(path)") }
        if let path = source.directStreamUrl { return URL(string: "\(serverURL)\(path)") }
        return nil
    }

    // MARK: - Private

    private func getItems(_ path: String) async throws -> [MediaItem] {
        let url = URL(string: "\(serverURL)\(path)")!
        var req = URLRequest(url: url)
        addAuth(to: &req)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(ItemsResponse.self, from: data).items
    }

    private func getArray(_ path: String) async throws -> [MediaItem] {
        let url = URL(string: "\(serverURL)\(path)")!
        var req = URLRequest(url: url)
        addAuth(to: &req)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode([MediaItem].self, from: data)
    }

    private func post(_ path: String, body: [String: Any]) async {
        guard let url = URL(string: "\(serverURL)\(path)"),
              let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuth(to: &req)
        req.httpBody = data
        try? await URLSession.shared.data(for: req)
    }

    private func addAuth(to req: inout URLRequest) {
        if let token { req.setValue(token, forHTTPHeaderField: "X-Emby-Token") }
        req.setValue(embyAuth(), forHTTPHeaderField: "X-Emby-Authorization")
    }

    private func embyAuth() -> String {
        "MediaBrowser Client=\"Jelly\", Device=\"AppleTV\", DeviceId=\"jelly-atv-001\", Version=\"1.0\""
    }

    private func deviceProfile(userId: String) -> [String: Any] {
        [
            "UserId": userId,
            "DeviceProfile": [
                "MaxStreamingBitrate": 80000000,
                "DirectPlayProfiles": [
                    ["Type": "Video", "Container": "mkv,mp4,ts",
                     "VideoCodec": "h264,hevc", "AudioCodec": "aac,mp3,ac3,eac3"]
                ],
                "TranscodingProfiles": [
                    ["Type": "Video", "Container": "ts", "VideoCodec": "h264",
                     "AudioCodec": "aac,mp3,ac3,eac3", "Protocol": "hls",
                     "Context": "Streaming", "MaxAudioChannels": "6"]
                ],
                "SubtitleProfiles": [
                    ["Format": "srt", "Method": "External"],
                    ["Format": "ass", "Method": "External"]
                ]
            ]
        ]
    }
}
