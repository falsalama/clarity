import Foundation

struct CapsulePreferences: Codable, Sendable, Equatable {
    // Typed core (stable keys)
    var outputStyle: String?              // e.g. "bullets"
    var optionsBeforeQuestions: Bool?
    var noTherapyFraming: Bool?
    var noPersona: Bool?
    var pseudonym: String? = nil

    // Multi-select fields (typed; avoids CSV truncation in extras)
    var dharmaPractices: [String] = []
    var dharmaDeities: [String] = []
    var dharmaTerms: [String] = []
    var dharmaMilestones: [String] = []

    // Open-ended extras (bounded, safe)
    var extras: [String: String] = [:]
}

struct CapsuleTendency: Codable, Sendable, Equatable, Identifiable {
    var id: UUID = UUID()
    var statement: String
    var evidenceCount: Int
    var firstSeenAt: Date
    var lastSeenAt: Date
    var isOverridden: Bool

    // NEW (optional; back-compat)
    var sourceKindRaw: String? = nil
    var sourceKey: String? = nil
}


struct CapsuleModel: Codable, Sendable, Equatable {
    var version: Int
    var learningEnabled: Bool
    var updatedAt: Date

    var preferences: CapsulePreferences
    var learnedTendencies: [CapsuleTendency]

    // Suppression token: projection ignores stats at/before this instant
    var learningResetAt: Date?

    static func empty() -> CapsuleModel {
        CapsuleModel(
            version: 1,
            learningEnabled: true,
            updatedAt: Date(),
            preferences: CapsulePreferences(),
            learnedTendencies: [],
            learningResetAt: nil
        )
    }
}

// MARK: - Cloud Tap learned cues export (bounded, optional)

extension CapsuleModel {
    func cloudTapLearnedCuesPayload(max limit: Int = 12, mode: CloudTapCapsuleMode = .reflect) -> [CloudTapLearnedCue]? {
        guard learningEnabled else { return nil }
        guard !learnedTendencies.isEmpty else { return nil }

        let iso = ISO8601DateFormatter()

        func isEphemeral(kindRaw: String?, key: String?) -> Bool {
            guard let kindRaw, let key else { return false }

            if kindRaw == PatternStatsEntity.Kind.release_pattern.rawValue { return true }

            if kindRaw == PatternStatsEntity.Kind.constraint_trigger.rawValue {
                return key.contains("low_sleep") || key.contains("low_energy") || key.contains("deadline_pressure")
            }

            if kindRaw == PatternStatsEntity.Kind.constraints_sensitivity.rawValue {
                return key == "time_pressure" || key == "low_energy"
            }

            return false
        }

        // For now: both reflect + talk exclude ephemeral to avoid polluting tone.
        // (We can loosen talk later if you want.)
        let filtered = learnedTendencies.filter { t in
            switch mode {
            case .reflect, .talk:
                return !isEphemeral(kindRaw: t.sourceKindRaw, key: t.sourceKey)
            }
        }

        // Bound per item
        let statementMax = 96
        let capped = filtered.prefix(limit)

        let cues: [CloudTapLearnedCue] = capped.map { t in
            let s = t.statement.trimmingCharacters(in: .whitespacesAndNewlines)
            let boundedStatement = String(s.prefix(statementMax))
            let boundedCount = max(1, min(999, t.evidenceCount))

            return CloudTapLearnedCue(
                statement: boundedStatement,
                evidenceCount: boundedCount,
                lastSeenAtISO: iso.string(from: t.lastSeenAt),
                kindRaw: t.sourceKindRaw,
                key: t.sourceKey
            )
        }

        return cues.isEmpty ? nil : cues
    }
}
