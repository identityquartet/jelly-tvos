import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let user: JellyUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case user = "User"
    }
}

struct JellyUser: Codable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}

struct MediaItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let seriesName: String?
    let seriesId: String?
    let seasonId: String?
    let indexNumber: Int?
    let parentIndexNumber: Int?
    let overview: String?
    let runTimeTicks: Int64?
    let userData: UserData?
    let primaryImageAspectRatio: Double?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case type = "Type"
        case seriesName = "SeriesName"
        case seriesId = "SeriesId"
        case seasonId = "SeasonId"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case overview = "Overview"
        case runTimeTicks = "RunTimeTicks"
        case userData = "UserData"
        case primaryImageAspectRatio = "PrimaryImageAspectRatio"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool { lhs.id == rhs.id }
}

struct UserData: Codable {
    let playbackPositionTicks: Int64?
    let played: Bool
    let playCount: Int

    enum CodingKeys: String, CodingKey {
        case playbackPositionTicks = "PlaybackPositionTicks"
        case played = "Played"
        case playCount = "PlayCount"
    }
}

struct ItemsResponse: Codable {
    let items: [MediaItem]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

struct PlaybackInfoResponse: Codable {
    let mediaSources: [MediaSource]
    let playSessionId: String

    enum CodingKeys: String, CodingKey {
        case mediaSources = "MediaSources"
        case playSessionId = "PlaySessionId"
    }
}

struct MediaSource: Codable {
    let id: String
    let transcodingUrl: String?
    let directStreamUrl: String?
    let mediaStreams: [MediaStream]?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case transcodingUrl = "TranscodingUrl"
        case directStreamUrl = "DirectStreamUrl"
        case mediaStreams = "MediaStreams"
    }
}

struct MediaStream: Codable {
    let index: Int
    let type: String
    let displayTitle: String?
    let isDefault: Bool?
    let language: String?

    enum CodingKeys: String, CodingKey {
        case index = "Index"
        case type = "Type"
        case displayTitle = "DisplayTitle"
        case isDefault = "IsDefault"
        case language = "Language"
    }
}
