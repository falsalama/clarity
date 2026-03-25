import Foundation

struct WelcomeManifest: Codable, Equatable {
    let sequenceIndex: Int
    let message: String
    let imageURL: String?
    let attribution: String?

    let nextSequenceIndex: Int?
    let nextMessage: String?
    let nextImageURL: String?
    let nextAttribution: String?

    // Kept optional for rollout safety / older payload compatibility
    let dateKey: String?
    let totalCount: Int?

    // Optional, server-driven tab subtitles
    let focusSubtitle: String?
    let practiceSubtitle: String?

    enum CodingKeys: String, CodingKey {
        case sequenceIndex
        case message
        case imageURL
        case attribution
        case nextSequenceIndex
        case nextMessage
        case nextImageURL
        case nextAttribution
        case dateKey
        case totalCount
        case focusSubtitle
        case practiceSubtitle
    }

    init(
        sequenceIndex: Int,
        message: String,
        imageURL: String?,
        attribution: String?,
        nextSequenceIndex: Int?,
        nextMessage: String?,
        nextImageURL: String?,
        nextAttribution: String?,
        dateKey: String?,
        totalCount: Int?,
        focusSubtitle: String?,
        practiceSubtitle: String?
    ) {
        self.sequenceIndex = sequenceIndex
        self.message = message
        self.imageURL = imageURL
        self.attribution = attribution
        self.nextSequenceIndex = nextSequenceIndex
        self.nextMessage = nextMessage
        self.nextImageURL = nextImageURL
        self.nextAttribution = nextAttribution
        self.dateKey = dateKey
        self.totalCount = totalCount
        self.focusSubtitle = focusSubtitle
        self.practiceSubtitle = practiceSubtitle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        sequenceIndex = try c.decodeIfPresent(Int.self, forKey: .sequenceIndex) ?? 0
        message = try c.decode(String.self, forKey: .message)
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        attribution = try c.decodeIfPresent(String.self, forKey: .attribution)

        nextSequenceIndex = try c.decodeIfPresent(Int.self, forKey: .nextSequenceIndex)
        nextMessage = try c.decodeIfPresent(String.self, forKey: .nextMessage)
        nextImageURL = try c.decodeIfPresent(String.self, forKey: .nextImageURL)
        nextAttribution = try c.decodeIfPresent(String.self, forKey: .nextAttribution)

        dateKey = try c.decodeIfPresent(String.self, forKey: .dateKey)
        totalCount = try c.decodeIfPresent(Int.self, forKey: .totalCount)

        focusSubtitle = try c.decodeIfPresent(String.self, forKey: .focusSubtitle)
        practiceSubtitle = try c.decodeIfPresent(String.self, forKey: .practiceSubtitle)
    }
}
