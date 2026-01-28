import Foundation

struct CapsulePreferences: Codable, Sendable, Equatable {
    // Typed core (stable keys)
    var outputStyle: String?              // e.g. "bullets"
    var optionsBeforeQuestions: Bool?
    var noTherapyFraming: Bool?
    var noPersona: Bool?

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

struct Capsule: Codable, Sendable, Equatable {
    var version: Int
    var learningEnabled: Bool
    var updatedAt: Date

    var preferences: CapsulePreferences
    var learnedTendencies: [CapsuleTendency]

    static func empty() -> Capsule {
        Capsule(
            version: 1,
            learningEnabled: true,
            updatedAt: Date(),
            preferences: CapsulePreferences(),
            learnedTendencies: []
        )
    }
}

