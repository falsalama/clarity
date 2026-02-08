import Foundation

enum SiriLaunchFlag {
    private static let suite = UserDefaults(suiteName: "group.uk.co.krunch.clarity")
    private static let key = "startCaptureRequested"

    static func requestStartCapture() {
        suite?.set(true, forKey: key)
    }

    static func consumeStartCaptureRequest() -> Bool {
        let requested = suite?.bool(forKey: key) ?? false
        if requested { suite?.set(false, forKey: key) }
        return requested
    }
}

