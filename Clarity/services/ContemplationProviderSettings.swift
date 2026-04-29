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
        case cloudTap

        var id: String { rawValue }

        var title: String {
            switch self {
            case .auto: return "Auto"
            case .deviceTapApple: return "Device Tap (Apple)"
            case .cloudTap: return "Cloud Tap"
            }
        }

        var footnote: String {
            switch self {
            case .auto:
                return "Prefer on-device when available; otherwise Cloud Tap (if enabled)."
            case .deviceTapApple:
                return "Uses the system on-device model when available."
            case .cloudTap:
                return "Uses Cloud Tap for all supported tools."
            }
        }
    }

    static var visibleChoices: [Choice] {
        var choices: [Choice] = [.cloudTap]

        if FeatureFlags.showAppleDeviceTapProvider {
            choices.append(.deviceTapApple)
        }

        return choices
    }

    static func isVisible(_ choice: Choice) -> Bool {
        visibleChoices.contains(choice)
    }

    private enum Keys {
        static let choice = "contemplation.provider.choice"
    }

    @Published var choice: Choice {
        didSet { UserDefaults.standard.set(choice.rawValue, forKey: Keys.choice) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.choice),
           let parsed = Choice(rawValue: raw),
           Self.isVisible(parsed)
        {
            self.choice = parsed
        } else {
            self.choice = .cloudTap
            UserDefaults.standard.set(Choice.cloudTap.rawValue, forKey: Keys.choice)
        }
    }
}
