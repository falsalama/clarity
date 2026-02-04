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
