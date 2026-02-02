// CloudTapService.swift

import Foundation

enum CloudTapError: Error, Equatable {
    case unavailable
    case http(Int, String)     // status code + response body (diagnostic)
    case decoding
    case network(String)
}

final class CloudTapService {
    private let session: URLSession

    private let overrideBaseURL: URL?
    private let overrideAnonKey: String?

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

    func clarityView(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-clarity-view")
    }

    func talkItThrough(_ reqBody: CloudTapTalkRequest) async throws -> CloudTapTalkResponse {
        try await postJSON(reqBody, to: "cloudtap-talkitthrough")
    }

    private func postJSON<T: Encodable, U: Decodable>(_ body: T, to endpoint: String) async throws -> U {
        let cfg = try resolveConfig()
        let url = resolveURL(base: cfg.baseURL, endpoint: endpoint)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 90

        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        req.setValue("Bearer \(cfg.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(cfg.supabaseAnonKey, forHTTPHeaderField: "apikey")

        // IMPORTANT: keep default key encoding (camelCase) because server expects appVersion, recordedAt, etc.
        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(body)

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

