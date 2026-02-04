import Foundation

struct CapsulePreferences: Codable, Sendable, Equatable {
    // Typed core (stable keys)
    var outputStyle: String?              // e.g. "bullets"
    var optionsBeforeQuestions: Bool?
    var noTherapyFraming: Bool?
    var noPersona: Bool?
    var pseudonym: String? = nil

    // Open-ended extras (bounded, safe)
    var extras: [String: String] = [:]
}

struct CapsuleTendency: Codable, Sendable, Equatable, Identifiable {
    var id: UUID = UUID()
    var statement: String                 // “tends to … when …”
    var evidenceCount: Int
    var firstSeenAt: Date
    var lastSeenAt: Date
    var isOverridden: Bool
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
    func cloudTapLearnedCuesPayload(max limit: Int = 12) -> [CloudTapLearnedCue]? {
        guard learningEnabled else { return nil }
        guard !learnedTendencies.isEmpty else { return nil }

        let iso = ISO8601DateFormatter()

        // Take top N as already curated/sorted by LearningSync
        let capped = learnedTendencies.prefix(limit)

        let items: [CloudTapLearnedCue] = capped.compactMap { t -> CloudTapLearnedCue? in
            let s = t.statement.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty else { return nil }

            // Bound fields defensively
            let boundedStatement = String(s.prefix(140))
            let boundedCount = max(1, min(999, t.evidenceCount))

            return CloudTapLearnedCue(
                statement: boundedStatement,
                evidenceCount: boundedCount,
                lastSeenAtISO: iso.string(from: t.lastSeenAt)
            )
        }

        return items.isEmpty ? nil : items
    }
}
