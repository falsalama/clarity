import Foundation

struct PortraitRecipe: Codable, Equatable {
    var version: Int

    // Face
    var faceShape: FaceShapeID
    var expression: ExpressionID
    var skinTone: SkinToneID
    var eyeColour: EyeColourID

    // Hair
    var hairStyle: HairStyleID
    var hairColour: HairColourID

    // Robe
    var robeStyle: RobeStyleID
    var robeColour: RobeColourID

    // Extras
    var glassesStyle: GlassesStyleID?     // nil = none
    var hatStyle: HatStyleID?             // nil = none
    var backgroundStyle: BackgroundStyleID

    static let currentVersion: Int = 2

    static var `default`: PortraitRecipe {
        PortraitRecipe(
            version: currentVersion,
            faceShape: .standard,
            expression: .neutral,
            skinTone: .tone4,
            eyeColour: .brown,
            hairStyle: .short,
            hairColour: .brown,
            robeStyle: .lay,
            robeColour: .maroon,
            glassesStyle: nil,
            hatStyle: nil,
            backgroundStyle: .none
        )
    }
}

extension PortraitRecipe {
    static func decodeOrDefault(from data: Data) -> PortraitRecipe {
        // v2 decode
        if let decoded = try? JSONDecoder().decode(PortraitRecipe.self, from: data) {
            return migrateIfNeeded(decoded)
        }

        // legacy v1 decode (best effort)
        if let legacy = try? JSONDecoder().decode(LegacyV1.self, from: data) {
            return legacy.toV2()
        }

        return .default
    }

    func encode() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    private static func migrateIfNeeded(_ r: PortraitRecipe) -> PortraitRecipe {
        if r.version == currentVersion { return r }
        // Future migrations go here.
        var copy = r
        copy.version = currentVersion
        return copy
    }

    private struct LegacyV1: Codable {
        var version: Int?
        var hairStyle: HairStyleID?
        var robeStyle: RobeStyleID?
        var glassesStyle: GlassesStyleID?
        var hatStyle: HatStyleID?

        var skinTone: SkinToneID?
        var hairColour: HairColourID?
        var eyeColour: EyeColourID?
        var robeColour: RobeColourID?
        var backgroundStyle: BackgroundStyleID?

        func toV2() -> PortraitRecipe {
            PortraitRecipe(
                version: PortraitRecipe.currentVersion,
                faceShape: .standard,
                expression: .neutral,
                skinTone: skinTone ?? .tone4,
                eyeColour: eyeColour ?? .brown,
                hairStyle: hairStyle ?? .short,
                hairColour: hairColour ?? .brown,
                robeStyle: robeStyle ?? .lay,
                robeColour: robeColour ?? .maroon,
                glassesStyle: glassesStyle,
                hatStyle: hatStyle,
                backgroundStyle: backgroundStyle ?? .none
            )
        }
    }
}

// MARK: - Enums

enum FaceShapeID: Int, Codable, CaseIterable { case slim = 0, standard = 1, round = 2 }
enum ExpressionID: Int, Codable, CaseIterable { case neutral = 0, soft = 1, fierce = 2 }

enum HairStyleID: Int, Codable, CaseIterable {
    case shaved = 0
    case short = 1
    case shoulder = 2
    case bun = 3
    case topknot = 4
    case longStraight = 5
    case longWavy = 6
    case longCurls = 7
    case tiedBack = 8
}

enum RobeStyleID: Int, Codable, CaseIterable { case lay = 0, robeA = 1, robeB = 2, ngakpa = 3 }

enum GlassesStyleID: Int, Codable, CaseIterable { case round = 0, square = 1, hex = 2, roundThin = 3, squareThin = 4 }

enum HatStyleID: Int, Codable, CaseIterable { case conicalStraw = 0, patternedCap = 1, monasticCap = 2 }

enum SkinToneID: Int, Codable, CaseIterable { case tone1, tone2, tone3, tone4, tone5, tone6, tone7, tone8 }

enum HairColourID: Int, Codable, CaseIterable {
    case black = 0
    case darkBrown = 1
    case brown = 2
    case lightBrown = 3
    case blonde = 4
    case grey = 5
    case white = 6
}

enum EyeColourID: Int, Codable, CaseIterable { case brown = 0, hazel = 1, blue = 2, green = 3, grey = 4 }

enum RobeColourID: Int, Codable, CaseIterable { case maroon = 0, saffron = 1, grey = 2, brown = 3, white = 4, indigo = 5 }

enum BackgroundStyleID: Int, Codable, CaseIterable { case none = 0, halo = 1, lotus = 2 }
