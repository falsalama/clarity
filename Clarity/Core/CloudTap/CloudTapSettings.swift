import Foundation
import Combine

@MainActor
final class CloudTapSettings: ObservableObject {
    private enum Keys {
        static let enabled = "cloudTap.enabled"
        static let showLaneBadges = "cloudTap.showLaneBadges"
    }

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled) }
    }

    @Published var showLaneBadges: Bool {
        didSet { UserDefaults.standard.set(showLaneBadges, forKey: Keys.showLaneBadges) }
    }

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)

        // Default true (transparent by default). If unset, register default.
        if UserDefaults.standard.object(forKey: Keys.showLaneBadges) == nil {
            UserDefaults.standard.set(true, forKey: Keys.showLaneBadges)
        }
        self.showLaneBadges = UserDefaults.standard.bool(forKey: Keys.showLaneBadges)
    }
}

