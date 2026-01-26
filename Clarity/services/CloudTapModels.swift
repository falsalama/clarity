import Foundation

// MARK: - Request

struct CloudTapReflectRequest: Codable {
    /// Redacted transcript text only.
    /// Audio, raw transcript, and placeholder maps never leave device.
    let text: String

    /// Optional ISO8601 timestamp for audit/debug (non-identifying).
    let recordedAt: String?

    /// Client identifier (e.g. "ios").
    let client: String

    /// App version for compatibility.
    let appVersion: String
}

// MARK: - Response

struct CloudTapReflectResponse: Codable {
    /// Plain text reflection response.
    let text: String
}

