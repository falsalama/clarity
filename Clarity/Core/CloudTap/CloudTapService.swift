import Foundation
import OSLog

enum CloudTapError: Error, Equatable {
    case unavailable
    case http(Int, String)
    case decoding
    case network(String)
}

extension CloudTapError {
    var userFacingMessage: String {
        switch self {
        case .unavailable:
            return "Cloud Tap is not available right now."
        case .http(401, _):
            return "Your cloud session has expired. Reopen the app and try again."
        case .http(402, _):
            return "Clarity Reflect access is not active yet. Open Account to subscribe or restore purchases."
        case .http(429, _):
            return "Cloud Tap is temporarily paused for this account. Try again later."
        case .http:
            return "Cloud Tap could not complete that request. Check your connection and try again."
        case .decoding:
            return "Cloud Tap returned an unexpected response. Try again later."
        case .network:
            return "Cloud Tap could not connect. Check your signal and try again."
        }
    }
}

final class CloudTapService {
    private let session: URLSession

    private let overrideBaseURL: URL?
    private let overrideAnonKey: String?

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Clarity",
        category: "CloudTap"
    )

    init(
        baseURL: URL? = nil,
        anonKey: String? = nil,
        session: URLSession = .shared
    ) {
        self.overrideBaseURL = baseURL
        self.overrideAnonKey = anonKey
        self.session = session
    }

    func reflect(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-reflect")
    }

    func options(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-options")
    }

    func questions(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-questions")
    }

    func perspective(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-clarity-perspective")
    }

    func talkItThrough(_ reqBody: CloudTapTalkRequest) async throws -> CloudTapTalkResponse {
        try await postJSON(reqBody, to: "cloudtap-talkitthrough")
    }

    func reflectSteps(programme: String = "starter_5day") async throws -> CloudTapStepsResponse {
        try await getJSON(from: "reflect-steps", query: [URLQueryItem(name: "programme", value: programme)])
    }

    func focusSteps(programme: String = "core") async throws -> CloudTapStepsResponse {
        try await getJSON(from: "focus-steps", query: [URLQueryItem(name: "programme", value: programme)])
    }

    func practiceSteps(programme: String = "core") async throws -> CloudTapStepsResponse {
        try await getJSON(from: "practice-steps", query: [URLQueryItem(name: "programme", value: programme)])
    }

    private func postJSON<T: Encodable, U: Decodable>(_ body: T, to endpoint: String) async throws -> U {
        let cfg = try resolveConfig()
        let url = resolveURL(base: cfg.baseURL, endpoint: endpoint)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 90

        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let accessToken = AppServices.supabaseAccessToken, !accessToken.isEmpty else {
            Self.logger.error("CloudTap POST missing user access token for \(endpoint, privacy: .public)")
            throw CloudTapError.unavailable
        }

        applySupabaseHeaders(to: &req, cfg: cfg, accessToken: accessToken)

        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(body)

        #if DEBUG
        CloudTapTraceHook.emit(endpoint: endpoint, requestBody: req.httpBody)
        #endif

        do {
            let (data, resp) = try await session.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0

            guard (200..<300).contains(code) else {
                let bodyText = String(data: data, encoding: .utf8) ?? ""
                throw CloudTapError.http(code, bodyText)
            }

            #if DEBUG
            CloudTapTraceHook.emitResponse(endpoint: endpoint, responseBody: data)
            #endif

            do {
                return try JSONDecoder().decode(U.self, from: data)
            } catch {
                throw CloudTapError.decoding
            }
        } catch let e as CloudTapError {
            throw e
        } catch {
            throw CloudTapError.network(String(describing: error))
        }
    }

    private func getJSON<U: Decodable>(
        from endpoint: String,
        query: [URLQueryItem] = []
    ) async throws -> U {
        let cfg = try resolveConfig()
        var url = resolveURL(base: cfg.baseURL, endpoint: endpoint)

        if !query.isEmpty, var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            comps.queryItems = query
            if let u = comps.url { url = u }
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 30

        req.setValue("application/json", forHTTPHeaderField: "Accept")
        applySupabaseHeaders(to: &req, cfg: cfg, accessToken: nil)

        do {
            let (data, resp) = try await session.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0

            guard (200..<300).contains(code) else {
                let bodyText = String(data: data, encoding: .utf8) ?? ""
                throw CloudTapError.http(code, bodyText)
            }

            do {
                return try JSONDecoder().decode(U.self, from: data)
            } catch {
                throw CloudTapError.decoding
            }
        } catch let e as CloudTapError {
            throw e
        } catch {
            throw CloudTapError.network(String(describing: error))
        }
    }

    private func applySupabaseHeaders(
        to req: inout URLRequest,
        cfg: CloudTapConfig.Config,
        accessToken: String?
    ) {
        req.setValue(cfg.supabaseAnonKey, forHTTPHeaderField: "apikey")

        if let accessToken, !accessToken.isEmpty {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            Self.logger.debug("CloudTap using user access token")
        } else {
            req.setValue("Bearer \(cfg.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            Self.logger.debug("CloudTap using anon key")
        }
    }

    private func resolveConfig() throws -> CloudTapConfig.Config {
        if let url = overrideBaseURL, let key = overrideAnonKey, !key.isEmpty {
            return CloudTapConfig.Config(baseURL: url, supabaseURL: nil, supabaseAnonKey: key)
        }

        guard case .available(let cfg) = CloudTapConfig.availability() else {
            throw CloudTapError.unavailable
        }
        return cfg
    }

    private func resolveURL(base: URL, endpoint: String) -> URL {
        let last = base.lastPathComponent
        if last.hasPrefix("cloudtap-") {
            return base.deletingLastPathComponent().appendingPathComponent(endpoint)
        }
        return base.appendingPathComponent(endpoint)
    }
}
