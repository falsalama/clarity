import Foundation

struct WALSnapshot: Codable, Sendable, Equatable {
    var version: Int = 1
    var updatedAtISO: String
    var primitives: [String: String]
    var tensions: [String]
    var unknowns: [String]
    var constraints: [String]
    var workingHypotheses: [String]
    var threadSummary: String?

    static func empty() -> WALSnapshot {
        WALSnapshot(
            version: 1,
            updatedAtISO: ISO8601DateFormatter().string(from: Date()),
            primitives: [:],
            tensions: [],
            unknowns: [],
            constraints: [],
            workingHypotheses: [],
            threadSummary: nil
        )
    }
}

