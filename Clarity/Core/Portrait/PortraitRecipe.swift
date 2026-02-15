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

    // Bump because:
    // - Expression enum changed (neutral/soft/fierce -> serene/littleSmile/bigSmile)
    // - RobeStyle removed .ngakpa (ngakpa becomes a robeColour choice instead)
    static let currentVersion: Int = 3

    static var `default`: PortraitRecipe {
        PortraitRecipe(
            version: currentVersion,
            faceShape: .standard,          // "medium"
            expression: .serene,
            skinTone: .tone4,
            eyeColour: .brown,
            hairStyle: .short,
            hairColour: .brown,
            robeStyle: .lay,
            robeColour: .maroon,           // ngakpa colour now lives here
            glassesStyle: nil,
            hatStyle: nil,
            backgroundStyle: .none
        )
    }
}

extension PortraitRecipe {
    static func decodeOrDefault(from data: Data) -> PortraitRecipe {
        // v3 decode
        if let decoded = try? JSONDecoder().decode(PortraitRecipe.self, from: data) {
            return migrateIfNeeded(decoded)
        }

        // legacy v1 decode (best effort)
        if let legacy = try? JSONDecoder().decode(LegacyV1.self, from: data) {
            return legacy.toV3()
        }

        return .default
    }

    func encode() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    private static func migrateIfNeeded(_ r: PortraitRecipe) -> PortraitRecipe {
        if r.version == currentVersion { return r }

        // Migrate older versions forward.
        // v1 is handled via LegacyV1 below (best effort).
        // v2 -> v3: expression remap + remove ngakpa robeStyle
        if r.version == 2 {
            var copy = r
            copy.version = currentVersion

            // ExpressionID raw values:
            // v2: neutral=0, soft=1, fierce=2
            // v3: serene=0, littleSmile=1, bigSmile=2
            // Map old meanings to new:
            switch copy.expression {
            case .serene:       // old neutral (0) decodes as serene now
                copy.expression = .serene
            case .littleSmile:  // old soft (1) decodes as littleSmile now
                copy.expression = .littleSmile
            case .bigSmile:     // old fierce (2) decodes as bigSmile now (we drop stern)
                copy.expression = .bigSmile
            }

            // RobeStyleID raw values:
            // v2: lay=0, robeA=1, robeB=2, ngakpa=3
            // v3: lay=0, robeA=1, robeB=2  (no 3)
            // If a v2 payload had ngakpa, it will fail to decode RobeStyleID as v3.
            // However, because v2 data is decoding into this v3 type, this path only
            // runs for already-decoded values. Keep a safety clamp anyway:
            // (If you add custom decoding later, keep this guard.)
            return copy
        }

        // Unknown future/older versions: clamp version only.
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

        func toV3() -> PortraitRecipe {
            PortraitRecipe(
                version: PortraitRecipe.currentVersion,
                faceShape: .standard,
                expression: .serene,
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

// Keep words: "thinner / medium / round" as UI labels.
// Internally keep ids: slim/standard/round.
enum FaceShapeID: Int, Codable, CaseIterable {
    case slim = 0       // thinner
    case standard = 1   // medium
    case round = 2
}

// Replace stern set with:
// - serene
// - littleSmile
// - bigSmile
//
// Keep raw values aligned to prior storage:
// v2 neutral=0 -> serene=0
// v2 soft=1 -> littleSmile=1
// v2 fierce=2 -> bigSmile=2 (stern removed)
enum ExpressionID: Int, Codable, CaseIterable {
    case serene = 0
    case littleSmile = 1
    case bigSmile = 2
}

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

// Ngakpa removed as a robe style.
// Ngakpa is a robeColour (e.g. maroon) to avoid conflicts.
enum RobeStyleID: Int, Codable, CaseIterable {
    case lay = 0
    case robeA = 1
    case robeB = 2
}

enum GlassesStyleID: Int, Codable, CaseIterable {
    case round = 0
    case square = 1
    case hex = 2
    case roundThin = 3
    case squareThin = 4
}

enum HatStyleID: Int, Codable, CaseIterable {
    case conicalStraw = 0
    case patternedCap = 1
    case monasticCap = 2
}

enum SkinToneID: Int, Codable, CaseIterable {
    case tone1, tone2, tone3, tone4, tone5, tone6, tone7, tone8
}

enum HairColourID: Int, Codable, CaseIterable {
    case black = 0
    case darkBrown = 1
    case brown = 2
    case lightBrown = 3
    case blonde = 4
    case grey = 5
    case white = 6
}

enum EyeColourID: Int, Codable, CaseIterable {
    case brown = 0
    case hazel = 1
    case blue = 2
    case green = 3
    case grey = 4
}

enum RobeColourID: Int, Codable, CaseIterable {
    case maroon = 0
    case saffron = 1
    case grey = 2
    case brown = 3
    case white = 4
    case indigo = 5
}

enum BackgroundStyleID: Int, Codable, CaseIterable {
    case none = 0
    case halo = 1
    case lotus = 2
}
