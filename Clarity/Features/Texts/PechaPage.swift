import Foundation

enum PechaSection: String, CaseIterable, Codable {
    case cover
    case title
    case image
    case opening
    case main
    case mantra
    case closing
    case dedication
}

enum PechaDisplayMode: String, CaseIterable, Codable {
    case triLingual
    case englishOnly
    case tibetanOnly

    var title: String {
        switch self {
        case .triLingual:
            return "3-line"
        case .englishOnly:
            return "English"
        case .tibetanOnly:
            return "Tibetan"
        }
    }
}

struct PechaPage: Identifiable, Codable, Hashable {
    let id: String
    let pageNumber: Int?
    let section: PechaSection

    let title: String?
    let imageName: String?

    let tibetan: String?
    let transliteration: String?
    let english: String?

    init(
        id: String,
        pageNumber: Int? = nil,
        section: PechaSection,
        title: String? = nil,
        imageName: String? = nil,
        tibetan: String? = nil,
        transliteration: String? = nil,
        english: String? = nil
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.section = section
        self.title = title
        self.imageName = imageName
        self.tibetan = tibetan
        self.transliteration = transliteration
        self.english = english
    }
}
