import Foundation

enum CloudTapConfig {
    /// Set in Target Info as a String:
    /// CloudTapBaseURL = https://<project-ref>.supabase.co/functions/v1/cloudtap-reflect
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

    /// Optional - only needed if other parts of the app use it.
    /// Set in Target Info as a String:
    /// SupabaseURL = https://<project-ref>.supabase.co
    static var supabaseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let url = URL(string: raw),
            !raw.isEmpty
        else {
            preconditionFailure("Missing/invalid Info.plist key: SupabaseURL")
        }
        return url
    }

    /// Needed for Supabase Edge Functions auth headers.
    /// Set in Target Info as a String:
    /// SupabaseAnonKey = <anon key>
    static var supabaseAnonKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            !key.isEmpty
        else {
            preconditionFailure("Missing/invalid Info.plist key: SupabaseAnonKey")
        }
        return key
    }
}

