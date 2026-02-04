// TurnRepository.swift
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

    // MARK: - Create (Audio capture)

    func createCaptureTurn(
        audioPath: String,
        recordedAt: Date = Date(),
        captureContext: CaptureContext = .unknown
    ) throws -> UUID {
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

    // MARK: - Create (Text capture)

    /// Creates a new Turn from pasted/imported text.
    /// Stores the redacted text as canonical transcript.
    func createTextTurn(
        redactedText: String,
        recordedAt: Date = Date(),
        captureContext: CaptureContext = .unknown
    ) throws -> UUID {
        let trimmed = redactedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "Clarity", code: 400, userInfo: [NSLocalizedDescriptionKey: "Text is empty"])
        }

        let id = UUID()
        let turn = TurnEntity(id: id)

        turn.sourceRaw = TurnSource.importedText.rawValue
        turn.captureContextRaw = captureContext.rawValue
        turn.recordedAt = recordedAt

        turn.audioPath = nil
        turn.audioBytes = 0

        // Do not store raw paste
        turn.transcriptRaw = nil
        turn.transcriptRedactedActive = trimmed

        // WAL: initialise (local-only)
        turn.walSnapshot = WALSnapshot.empty(now: Date())
        turn.walUpdatedAt = Date()
        turn.walVersion = 1

        turn.stateRaw = TurnState.ready.rawValue

        context.insert(turn)
        try context.save()
        return id
    }

    // MARK: - State updates

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
            let trimmed = turn.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.caseInsensitiveCompare("Untitled") == .orderedSame {
                turn.title = titleIfAuto
            }
        }

        // WAL: no placeholder stamping here; validated snapshots are persisted via updateWAL(id:snapshot:)
        turn.stateRaw = TurnState.ready.rawValue
        try context.save()
    }

    func markFailed(id: UUID, debug: String) throws {
        guard let turn = try fetch(id: id) else { return }
        turn.stateRaw = TurnState.failed.rawValue
        turn.errorDebugMessage = debug
        try context.save()
    }

    // MARK: - WAL update (C2)

    func updateWAL(id: UUID, snapshot: ValidatedWalSnapshot) throws {
        guard let turn = try fetch(id: id) else { return }
        // Store as compact JSON into existing walJSON slot for now
        if let data = try? JSONEncoder().encode(snapshot.snapshot) {
            turn.walJSON = data
        }
        turn.walUpdatedAt = Date()
        turn.walVersion = max(turn.walVersion, snapshot.snapshot.version)
        try context.save()
    }

    // MARK: - Delete

    func delete(id: UUID) throws {
        guard let entity = try fetch(id: id) else { return }

        // Best-effort local audio delete
        FileStore.removeIfExists(atPath: entity.audioPath)

        context.delete(entity)
        try context.save()
    }
}
