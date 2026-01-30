import Foundation

enum CloudTapConfig {

    // MARK: - Availability

    enum Availability: Equatable {
        case available(Config)
        case unavailable(Reason)

        enum Reason: Equatable, CustomStringConvertible {
            case missingBaseURL
            case invalidBaseURL(String)
            case missingAnonKey
            case missingSupabaseURL
            case invalidSupabaseURL(String)

            var description: String {
                switch self {
                case .missingBaseURL:
                    return "Cloud Tap is not configured."
                case .invalidBaseURL:
                    return "Cloud Tap base URL is invalid."
                case .missingAnonKey:
                    return "Cloud Tap anon key is missing."
                case .missingSupabaseURL:
                    return "Supabase URL is missing."
                case .invalidSupabaseURL:
                    return "Supabase URL is invalid."
                }
            }
        }
    }

    struct Config: Equatable {
        let baseURL: URL
        let supabaseURL: URL?
        let supabaseAnonKey: String
    }

    /// Single source of truth for whether Cloud Tap can run.
    static func availability() -> Availability {
        // Base URL (required)
        guard let rawBase = infoString("CloudTapBaseURL") else {
            debugMisconfig("Missing Info.plist key: CloudTapBaseURL")
            return .unavailable(.missingBaseURL)
        }
        guard let baseURL = URL(string: rawBase) else {
            debugMisconfig("Invalid Info.plist key: CloudTapBaseURL = \(rawBase)")
            return .unavailable(.invalidBaseURL(rawBase))
        }

        // Anon key (required)
        guard let anonKey = infoString("SupabaseAnonKey"), !anonKey.isEmpty else {
            debugMisconfig("Missing Info.plist key: SupabaseAnonKey")
            return .unavailable(.missingAnonKey)
        }

        // Supabase URL (optional, but validated if present)
        let supabaseURL: URL?
        if let rawSupabase = infoString("SupabaseURL") {
            if let url = URL(string: rawSupabase) {
                supabaseURL = url
            } else {
                debugMisconfig("Invalid Info.plist key: SupabaseURL = \(rawSupabase)")
                return .unavailable(.invalidSupabaseURL(rawSupabase))
            }
        } else {
            supabaseURL = nil
        }

        return .available(
            Config(
                baseURL: baseURL,
                supabaseURL: supabaseURL,
                supabaseAnonKey: anonKey
            )
        )
    }

    // MARK: - Backwards-compat convenience (do not crash)

    /// Prefer `availability()` in new code. Returns nil if unavailable.
    static var baseURL: URL? {
        guard case .available(let cfg) = availability() else { return nil }
        return cfg.baseURL
    }

    /// Optional. Returns nil if missing/invalid.
    static var supabaseURL: URL? {
        guard case .available(let cfg) = availability() else { return nil }
        return cfg.supabaseURL
    }

    /// Prefer `availability()` in new code. Returns nil if unavailable.
    static var supabaseAnonKey: String? {
        guard case .available(let cfg) = availability() else { return nil }
        return cfg.supabaseAnonKey
    }

    // MARK: - Helpers

    private static func infoString(_ key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func debugMisconfig(_ message: String) {
        #if DEBUG
        assertionFailure(message)
        #endif
    }
}

