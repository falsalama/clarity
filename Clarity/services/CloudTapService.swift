import Foundation

enum CloudTapError: Error {
    case invalidURL
    case http(Int)
    case decoding
}

final class CloudTapService {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func reflect(_ reqBody: CloudTapReflectRequest) async throws -> CloudTapReflectResponse {
        guard let url = URL(string: "/v1/cloudtap/reflect", relativeTo: baseURL) else {
            throw CloudTapError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
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

