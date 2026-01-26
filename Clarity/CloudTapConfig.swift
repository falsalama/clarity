import Foundation

enum CloudTapConfig {
    /// Set this in Info.plist as a String:
    /// CloudTapBaseURL = https://YOUR_DOMAIN
    static var baseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "CloudTapBaseURL") as? String,
            let url = URL(string: raw),
            !raw.isEmpty
        else {
            preconditionFailure("Missing/invalid Info.plist key: CloudTapBaseURL")
        }
        return url
    }
}

