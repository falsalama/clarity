import Foundation

struct PortraitRecipe: Codable, Equatable {

    var hair: HairID?
    var robe: RobeID?
    var halo: HaloID?
    var glasses: GlassesID?
    
    static let `default` = PortraitRecipe(
        hair: nil,
        robe: nil,
        halo: nil,
        glasses: nil
    )

    func encode() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    static func decodeOrDefault(from data: Data?) -> PortraitRecipe {
        guard
            let data,
            let decoded = try? JSONDecoder().decode(PortraitRecipe.self, from: data)
        else {
            return .default
        }
        return decoded
    }
}

enum HairID: String, Codable, CaseIterable {
    case shorthair
    case longhair
    case topknot
    case yogi
}

enum RobeID: String, Codable, CaseIterable {
    case lay
    case western
    case koromo
}

enum HaloID: String, Codable, CaseIterable {
    case golden
    case silver
    case rainbow
}

enum GlassesID: String, Codable, CaseIterable {
    case round  = "glasses-round"
    case square = "glasses-square"
}
