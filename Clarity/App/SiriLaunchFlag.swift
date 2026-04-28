import Foundation

enum SiriLaunchFlag {
    private static let key = "startCaptureRequested"

    static func requestStartCapture() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func consumeStartCaptureRequest() -> Bool {
        let requested = UserDefaults.standard.bool(forKey: key)
        if requested { UserDefaults.standard.set(false, forKey: key) }
        return requested
    }
}
