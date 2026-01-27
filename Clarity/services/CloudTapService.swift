import Foundation

enum CloudTapError: Error {
    case http(Int)
    case decoding
}

final class CloudTapService {
    private let baseURL: URL
    private let anonKey: String
    private let session: URLSession

    /// baseURL should be: https://<project-ref>.supabase.co/functions/v1
    /// anonKey should be your Supabase anon key
    init(
        baseURL: URL = CloudTapConfig.baseURL,
        anonKey: String = CloudTapConfig.supabaseAnonKey,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.session = session
    }

    func reflect(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        // Edge function name: "cloudtap"
        // Route: "reflect"
        let url = baseURL.appendingPathComponent("cloudtap-reflect")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Supabase Edge Functions auth
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")

        req.httpBody = try JSONEncoder().encode(reqBody)

        let (data, resp) = try await session.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw CloudTapError.http(code) }

        do {
            return try JSONDecoder().decode(CloudTapReflectResponse.self, from: data)
        } catch {
            throw CloudTapError.decoding
        }
    }
}

