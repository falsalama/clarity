import Foundation

enum PortraitCatalogue {
    static func title(for face: FaceShapeID) -> String {
        switch face {
        case .slim: return "Slim"
        case .standard: return "Standard"
        case .round: return "Round"
        }
    }

    static func title(for expression: ExpressionID) -> String {
        switch expression {
        case .neutral: return "Neutral"
        case .soft: return "Soft"
        case .fierce: return "Fierce"
        }
    }

    static func title(for hair: HairStyleID) -> String {
        switch hair {
        case .shaved: return "Shaved"
        case .short: return "Short"
        case .shoulder: return "Shoulder length"
        case .bun: return "Bun"
        case .topknot: return "Topknot"
        case .longStraight: return "Long (straight)"
        case .longWavy: return "Long (wavy)"
        case .longCurls: return "Long (curls)"
        case .tiedBack: return "Tied back"
        }
    }

    static func title(for robe: RobeStyleID) -> String {
        switch robe {
        case .lay: return "Lay"
        case .robeA: return "Robe A"
        case .robeB: return "Robe B"
        case .ngakpa: return "Ngakpa (two-tone)"
        }
    }

    static func title(for glasses: GlassesStyleID) -> String {
        switch glasses {
        case .round: return "Round"
        case .square: return "Square"
        case .hex: return "Hex"
        case .roundThin: return "Round (thin)"
        case .squareThin: return "Square (thin)"
        }
    }

    static func title(for hat: HatStyleID) -> String {
        switch hat {
        case .conicalStraw: return "Conical hat"
        case .patternedCap: return "Patterned cap"
        case .monasticCap: return "Monastic cap"
        }
    }

    static func title(for background: BackgroundStyleID) -> String {
        switch background {
        case .none: return "None"
        case .halo: return "Halo"
        case .lotus: return "Lotus"
        }
    }

    static func title(for hairColour: HairColourID) -> String {
        switch hairColour {
        case .black: return "Black"
        case .darkBrown: return "Dark Brown"
        case .brown: return "Brown"
        case .lightBrown: return "Light Brown"
        case .blonde: return "Blonde"
        case .grey: return "Grey"
        case .white: return "White"
        }
    }

    static func title(for eyeColour: EyeColourID) -> String {
        switch eyeColour {
        case .brown: return "Brown"
        case .hazel: return "Hazel"
        case .blue: return "Blue"
        case .green: return "Green"
        case .grey: return "Grey"
        }
    }

    static func title(for robeColour: RobeColourID) -> String {
        switch robeColour {
        case .maroon: return "Maroon"
        case .saffron: return "Saffron"
        case .grey: return "Grey"
        case .brown: return "Brown"
        case .white: return "White"
        case .indigo: return "Indigo"
        }
    }
}
