// CloudTapService.swift

import Foundation
import OSLog

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

    // MARK: - Steps (DB-fed content)

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

        req.setValue("Bearer \(cfg.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(cfg.supabaseAnonKey, forHTTPHeaderField: "apikey")

        // IMPORTANT: keep default key encoding (camelCase) because server expects appVersion, recordedAt, etc.
        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(body)

        // ============================================================
        // MARK: - PRISM/TRACE DEBUG HOOK (TEMPORARY)
        //
        // Purpose:
        // - Print a small summary of what we EXPORT to CloudTap:
        //   preference key count + learnedCues count + key preview.
        //
        // Requirements:
        // - Add file: Clarity/Core/CloudTap/CloudTapTraceHook.swift
        //
        // Remove later:
        // - Delete this block (and the response block below)
        // - Delete CloudTapTraceHook.swift
        // ============================================================
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

            // ============================================================
            // MARK: - PRISM/TRACE DEBUG HOOK (TEMPORARY)
            //
            // Purpose:
            // - Print a short snippet of what we RECEIVE from CloudTap.
            //
            // Remove later:
            // - Delete this block (and the export block above)
            // - Delete CloudTapTraceHook.swift
            // ============================================================
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
        req.setValue("Bearer \(cfg.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(cfg.supabaseAnonKey, forHTTPHeaderField: "apikey")

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
