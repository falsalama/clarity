import Foundation

enum CloudTapError: Error {
    case http(Int)
    case decoding
}

final class CloudTapService {
    private let baseURL: URL
    private let anonKey: String
    private let session: URLSession

    init(
        baseURL: URL = CloudTapConfig.baseURL,
        anonKey: String = CloudTapConfig.supabaseAnonKey,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.session = session
    }

    private func postJSON<T: Encodable, U: Decodable>(_ body: T, to path: String) async throws -> U {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
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

    // Single-shot
    func reflect(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-reflect")
    }

    func options(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-options")
    }

    func questions(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        try await postJSON(reqBody, to: "cloudtap-questions")
    }

    // Multi-turn
    func talkItThrough(_ reqBody: CloudTapTalkRequest) async throws -> CloudTapTalkResponse {
        try await postJSON(reqBody, to: "cloudtap-talkitthrough")
    }
}

