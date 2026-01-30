import Foundation

enum CloudTapError: Error, Equatable {
    case unavailable
    case http(Int)
    case decoding
}

final class CloudTapService {
    private let session: URLSession

    // Optional overrides (lets existing call sites keep working)
    private let overrideBaseURL: URL?
    private let overrideAnonKey: String?

    // Backwards-compatible
    init(
        baseURL: URL? = nil,
        anonKey: String? = nil,
        session: URLSession = .shared
    ) {
        self.overrideBaseURL = baseURL
        self.overrideAnonKey = anonKey
        self.session = session
    }

    // MARK: - Public API

    func reflect(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-reflect")
    }

    func options(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-options")
    }

    func questions(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-questions")
    }

    func clarityView(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-clarity-view")
    }


    func talkItThrough(_ reqBody: CloudTapTalkRequest) async throws -> CloudTapTalkResponse {
        try await postJSON(reqBody, to: "cloudtap-talkitthrough")
    }

    // MARK: - Core

    private func postJSON<T: Encodable, U: Decodable>(_ body: T, to endpoint: String) async throws -> U {
        let cfg = try resolveConfig()
        let url = resolveURL(base: cfg.baseURL, endpoint: endpoint)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(cfg.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(cfg.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await session.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw CloudTapError.http(code) }

        do {
            return try JSONDecoder().decode(U.self, from: data)
        } catch {
            throw CloudTapError.decoding
        }
    }

    private func resolveConfig() throws -> CloudTapConfig.Config {
        // If call site passed explicit config, use it (no behaviour change).
        if let url = overrideBaseURL, let key = overrideAnonKey, !key.isEmpty {
            return CloudTapConfig.Config(baseURL: url, supabaseURL: nil, supabaseAnonKey: key)
        }

        // Otherwise, require runtime config (fail-closed).
        guard case .available(let cfg) = CloudTapConfig.availability() else {
            throw CloudTapError.unavailable
        }
        return cfg
    }

    /// Supports both:
    /// A) base = .../functions/v1      -> appends /<endpoint>
    /// B) base = .../functions/v1/cloudtap-reflect -> replaces last component with <endpoint>
    private func resolveURL(base: URL, endpoint: String) -> URL {
        let last = base.lastPathComponent
        if last.hasPrefix("cloudtap-") {
            return base.deletingLastPathComponent().appendingPathComponent(endpoint)
        }
        return base.appendingPathComponent(endpoint)
    }
}

