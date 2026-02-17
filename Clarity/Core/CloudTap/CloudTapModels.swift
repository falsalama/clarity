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

    // NEW (optional; back-compat)
    let kindRaw: String?
    let key: String?
}

// MARK: - Capsule snapshot (bounded, safe)

struct CloudTapCapsuleSnapshot: Codable, Sendable, Equatable {
    let version: Int
    let updatedAt: String
    let preferences: [String: String]
    let learnedCues: [CloudTapLearnedCue]?    // optional, gated by learningEnabled

    static func fromCapsule(_ capsule: CapsuleModel, mode: CloudTapCapsuleMode = .reflect) -> CloudTapCapsuleSnapshot {
        CloudTapCapsuleSnapshot(
            version: capsule.version,
            updatedAt: ISO8601DateFormatter().string(from: capsule.updatedAt),
            preferences: boundPreferences(capsule.preferences),
            learnedCues: capsule.cloudTapLearnedCuesPayload(max: 12, mode: mode) // returns nil unless learningEnabled && non-empty
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

