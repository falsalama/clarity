import Foundation
import SwiftData

@MainActor
final class TurnRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchAllNewestFirst() throws -> [TurnEntity] {
        let descriptor = FetchDescriptor<TurnEntity>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> TurnEntity? {
        let descriptor = FetchDescriptor<TurnEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - Create (Capture)

    /// Creates a new capture Turn and persists it. Returns the new Turn id.
    func createCaptureTurn(audioPath: String, recordedAt: Date = Date(), captureContext: CaptureContext = .unknown) throws -> UUID {
        let id = UUID()
        let turn = TurnEntity(id: id)

        turn.sourceRaw = TurnSource.captured.rawValue
        turn.captureContextRaw = captureContext.rawValue
        turn.recordedAt = recordedAt
        turn.stateRaw = TurnState.queued.rawValue
        turn.audioPath = audioPath

        context.insert(turn)
        try context.save()
        return id
    }

    // MARK: - State updates

    /// Marks a Turn as ready and writes transcript fields. Title is written only if provided.
    func markReady(
        id: UUID,
        endedAt: Date = Date(),
        transcriptRaw: String?,
        transcriptRedactedActive: String,
        redactionVersion: Int = 1,
        redactionTimestamp: Date = Date(),
        titleIfAuto: String? = nil
    ) throws {
        guard let turn = try fetch(id: id) else {
            throw NSError(domain: "Clarity", code: 404, userInfo: [NSLocalizedDescriptionKey: "Turn not found"])
        }

        turn.endedAt = endedAt
        turn.durationSeconds = max(0, endedAt.timeIntervalSince(turn.recordedAt))

        turn.transcriptRaw = transcriptRaw
        turn.transcriptRedactedActive = transcriptRedactedActive
        turn.redactionTimestamp = redactionTimestamp
        turn.redactionVersion = max(turn.redactionVersion, redactionVersion)

        if let titleIfAuto, !titleIfAuto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Only set if the user hasn’t manually named it (empty or default).
            let trimmed = turn.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.caseInsensitiveCompare("Untitled") == .orderedSame {
                turn.title = titleIfAuto
            }
        }

        turn.stateRaw = TurnState.ready.rawValue
        try context.save()
    }

    func markFailed(id: UUID, debug: String) throws {
        guard let turn = try fetch(id: id) else { return }
        turn.stateRaw = TurnState.failed.rawValue
        turn.errorDebugMessage = debug
        try context.save()
    }

    // MARK: - Delete

    func delete(id: UUID) throws {
        guard let entity = try fetch(id: id) else { return }

        // Delete local audio first (best-effort).
        FileStore.removeIfExists(atPath: entity.audioPath)

        context.delete(entity)
        try context.save()
    }
}

