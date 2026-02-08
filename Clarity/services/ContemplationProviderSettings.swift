import Foundation
import Combine


/// User-facing selection for how contemplations are generated.
///
/// - Cloud Tap: opt-in server processing.
/// - Device Tap: on-device processing.
@MainActor
final class ContemplationProviderSettings: ObservableObject {
    enum Choice: String, CaseIterable, Identifiable {
        case auto
        case deviceTapApple
        case deviceTapLlama
        case cloudTap

        var id: String { rawValue }

        var title: String {
            switch self {
            case .auto: return "Auto"
            case .deviceTapApple: return "Device Tap (Apple)"
            case .deviceTapLlama: return "Device Tap (Llama)"
            case .cloudTap: return "Cloud Tap"
            }
        }

        var footnote: String {
            switch self {
            case .auto:
                return "Prefer on-device when available; otherwise Cloud Tap (if enabled)."
            case .deviceTapApple:
                return "Uses the system on-device model when available."
            case .deviceTapLlama:
                return "Uses a bundled on-device model (if installed)."
            case .cloudTap:
                return "Uses Cloud Tap for all supported tools."
            }
        }
    }

    private enum Keys {
        static let choice = "contemplation.provider.choice"
    }

    @Published var choice: Choice {
        didSet { UserDefaults.standard.set(choice.rawValue, forKey: Keys.choice) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.choice),
           let parsed = Choice(rawValue: raw)
        {
            self.choice = parsed
        } else {
            self.choice = .auto
        }
    }
}
