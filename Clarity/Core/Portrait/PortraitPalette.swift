import SwiftUI

enum PortraitPalette {
    static func skin(_ id: SkinToneID) -> Color {
        switch id {
        case .tone1: return Color(red: 0.99, green: 0.92, blue: 0.88)
        case .tone2: return Color(red: 0.97, green: 0.86, blue: 0.78)
        case .tone3: return Color(red: 0.93, green: 0.78, blue: 0.66)
        case .tone4: return Color(red: 0.86, green: 0.66, blue: 0.52)
        case .tone5: return Color(red: 0.72, green: 0.52, blue: 0.38)
        case .tone6: return Color(red: 0.58, green: 0.40, blue: 0.28)
        case .tone7: return Color(red: 0.45, green: 0.30, blue: 0.20)
        case .tone8: return Color(red: 0.32, green: 0.22, blue: 0.16)
        }
    }

    static func hair(_ id: HairColourID) -> Color {
        switch id {
        case .black: return .black
        case .darkBrown: return Color(red: 0.22, green: 0.16, blue: 0.12)
        case .brown: return Color(red: 0.44, green: 0.32, blue: 0.24)
        case .lightBrown: return Color(red: 0.60, green: 0.46, blue: 0.32)
        case .blonde: return Color(red: 0.78, green: 0.70, blue: 0.44)
        case .grey: return .gray
        case .white: return Color(red: 0.96, green: 0.96, blue: 0.97)
        }
    }

    static func eyes(_ id: EyeColourID) -> Color {
        switch id {
        case .brown: return Color(red: 0.30, green: 0.20, blue: 0.14)
        case .hazel: return Color(red: 0.36, green: 0.30, blue: 0.16)
        case .blue: return Color(red: 0.18, green: 0.38, blue: 0.78)
        case .green: return Color(red: 0.18, green: 0.55, blue: 0.35)
        case .grey: return .gray
        }
    }

    static func robe(_ id: RobeColourID) -> Color {
        switch id {
        case .maroon: return Color(red: 0.36, green: 0.12, blue: 0.16)
        case .saffron: return Color(red: 0.82, green: 0.52, blue: 0.14)
        case .grey: return .gray
        case .brown: return Color(red: 0.36, green: 0.26, blue: 0.18)
        case .white: return Color(red: 0.96, green: 0.96, blue: 0.97)
        case .indigo: return Color(red: 0.08, green: 0.12, blue: 0.28)
        }
    }

    static func background(_ id: BackgroundStyleID) -> Color? {
        switch id {
        case .none: return nil
        case .halo: return Color.yellow.opacity(0.28)
        case .lotus: return Color.purple.opacity(0.22)
        }
    }
}
