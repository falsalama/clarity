import Foundation

// MARK: - Single-shot (reflect/options/questions)

struct CloudTapReflectRequest: Codable {
    let text: String
    let recordedAt: String?
    let client: String
    let appVersion: String
}

struct CloudTapReflectResponse: Decodable {
    let text: String
    let prompt_version: String
}

// MARK: - Multi-turn (talk-it-through)

struct CloudTapTalkRequest: Codable {
    let text: String
    let recordedAt: String?
    let client: String
    let appVersion: String
    let previous_response_id: String?
}

struct CloudTapTalkResponse: Decodable {
    let text: String
    let response_id: String
    let prompt_version: String
}
