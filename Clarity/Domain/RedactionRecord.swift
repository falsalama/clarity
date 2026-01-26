import Foundation

struct RedactionRecord: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let turnId: UUID
    let version: Int
    let timestamp: Date
    let inputHash: String
    let textRedacted: String

    init(
        id: UUID = UUID(),
        turnId: UUID,
        version: Int,
        timestamp: Date = Date(),
        inputHash: String,
        textRedacted: String
    ) {
        self.id = id
        self.turnId = turnId
        self.version = version
        self.timestamp = timestamp
        self.inputHash = inputHash
        self.textRedacted = textRedacted
    }
}

