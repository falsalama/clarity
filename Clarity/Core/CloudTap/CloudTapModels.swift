import Foundation

// MARK: - Capsule mode (controls what we inject)

enum CloudTapCapsuleMode: String, Codable, Sendable {
    case reflect
    case talk
}

// MARK: - Learned cues (bounded, optional)

struct CloudTapLearnedCue: Codable, Sendable, Equatable {
    let statement: String
    let evidenceCount: Int
    let lastSeenAtISO: String

    // Optional; back-compat
    let kindRaw: String?
    let key: String?
}

// MARK: - Capsule snapshot (bounded, safe)

struct CloudTapCapsuleSnapshot: Codable, Sendable, Equatable {
    let version: Int
    let updatedAt: String
    let preferences: [String: String]?
    let learnedCues: [CloudTapLearnedCue]?

    static func fromCapsule(_ capsule: CapsuleModel, mode: CloudTapCapsuleMode = .reflect) -> CloudTapCapsuleSnapshot {
        CloudTapCapsuleSnapshot(
            version: capsule.version,
            updatedAt: ISO8601DateFormatter().string(from: capsule.updatedAt),
            preferences: boundPreferences(capsule.preferences),
            learnedCues: capsule.cloudTapLearnedCuesPayload(max: 12, mode: mode)
        )
    }

    private static func boundPreferences(_ p: CapsulePreferences) -> [String: String] {
        var out: [String: String] = [:]

        // Typed core
        if let s = p.outputStyle, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            out["output_style"] = String(s.prefix(128))
        }
        if let b = p.optionsBeforeQuestions {
            out["options_before_questions"] = b ? "true" : "false"
        }
        if let b = p.noTherapyFraming {
            out["no_therapy_framing"] = b ? "true" : "false"
        }
        if let b = p.noPersona {
            out["no_persona"] = b ? "true" : "false"
        }

        // Multi-select (typed; inject compact JSON arrays)
        func encodeJSONArray(_ values: [String], maxLen: Int) -> String? {
            let cleaned = values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !cleaned.isEmpty else { return nil }

            if let data = try? JSONEncoder().encode(cleaned),
               let s = String(data: data, encoding: .utf8) {
                return String(s.prefix(maxLen))
            }
            return nil
        }

        if let s = encodeJSONArray(p.dharmaPractices, maxLen: 512) { out["dharma:practices"] = s }
        if let s = encodeJSONArray(p.dharmaDeities, maxLen: 512) { out["dharma:deities"] = s }
        if let s = encodeJSONArray(p.dharmaTerms, maxLen: 512) { out["dharma:terms"] = s }
        if let s = encodeJSONArray(p.dharmaMilestones, maxLen: 512) { out["dharma:milestones"] = s }

        // Extras (bounded again defensively)
        let maxItems = 24
        let keyMax = 32
        let valueMax = 128

        let keys = p.extras.keys.sorted().prefix(maxItems)
        for k in keys {
            let kk = String(k.prefix(keyMax))
            let vv = String((p.extras[k] ?? "").prefix(valueMax))
            if !vv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                out[kk] = vv
            }
        }

        return out
    }
}

// MARK: - Single-shot (reflect/options/questions/perspective)

struct CloudTapReflectRequest: Codable {
    let text: String
    let recordedAt: String?
    let client: String
    let appVersion: String
    let capsule: CloudTapCapsuleSnapshot?
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
    let capsule: CloudTapCapsuleSnapshot?
}

struct CloudTapTalkResponse: Decodable {
    let text: String
    let response_id: String
    let prompt_version: String
}
