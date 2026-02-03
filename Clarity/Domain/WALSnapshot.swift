// WALSnapshot.swift
import Foundation

struct WALSnapshot: Codable, Sendable, Equatable {
    var version: Int = 1
    var updatedAtISO: String

    // Small, bounded facts
    var primitives: [String: String]        // small key/value facts, bounded

    // 1–4
    var tensions: [String]

    // 1–6
    var unknowns: [String]

    // 0–6
    var constraints: [String]

    // 0–4
    var workingHypotheses: [String]

    // 0–280 chars
    var threadSummary: String?

    static func empty(now: Date = Date()) -> WALSnapshot {
        WALSnapshot(
            version: 1,
            updatedAtISO: ISO8601DateFormatter().string(from: now),
            primitives: [:],
            tensions: [],
            unknowns: [],
            constraints: [],
            workingHypotheses: [],
            threadSummary: nil
        )
    }
}

enum WALCodec {
    static func decode(_ data: Data) -> WALSnapshot? {
        guard data.isEmpty == false else { return nil }

        // Treat "{}" as nil/empty to avoid noisy snapshots
        if let s = String(data: data, encoding: .utf8) {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == "{}" || trimmed == "null" { return nil }
        }

        return try? JSONDecoder().decode(WALSnapshot.self, from: data)
    }

    static func encode(_ snapshot: WALSnapshot?) -> Data {
        guard let snapshot else { return Data("{}".utf8) }
        return (try? JSONEncoder().encode(snapshot)) ?? Data("{}".utf8)
    }
}

// Domain convenience
extension Turn {
    var walSnapshot: WALSnapshot? {
        get { WALCodec.decode(walJSON) }
        set { walJSON = WALCodec.encode(newValue) }
    }
}

// Optional: persistence convenience (if you want the same API on the SwiftData model)
extension TurnEntity {
    var walSnapshot: WALSnapshot? {
        get { WALCodec.decode(walJSON) }
        set { walJSON = WALCodec.encode(newValue) }
    }
}

