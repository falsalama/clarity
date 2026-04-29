import Foundation
import SwiftUI

enum FeatureFlags {
    /// Cloud Tap remains the default. Apple Device Tap is available as a
    /// privacy-first on-device option on compatible devices.
    static let showAppleDeviceTapProvider = true

    static var showModelProviderSettings: Bool {
        showAppleDeviceTapProvider
    }

    static var paywallGeneratedReflectTools: Bool {
        true
    }
}
