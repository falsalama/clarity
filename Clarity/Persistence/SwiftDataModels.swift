import Foundation
import SwiftData

// MARK: - TurnEntity (Persistence only)

@Model
final class TurnEntity {

    // MARK: Identity

    @Attribute(.unique)
    var id: UUID

    // MARK: Core metadata

    var sourceRaw: String = TurnSource.captured.rawValue
    var recordedAt: Date = Date()
    var endedAt: Date?
    var durationSeconds: Double?
    var sourceOriginalDate: Date?

    var captureContextRaw: String = CaptureContext.unknown.rawValue

    // MARK: Title

    /// User-editable title. Empty string means "no manual title".
    var title: String = ""

    // MARK: Audio

    var audioPath: String?
    var audioBytes: Int64 = 0

    // MARK: Transcript

    /// Local-only, never leaves device unless user explicitly exports.
    var transcriptRaw: String?

    /// Canonical display transcript and any cloud payload.
    var transcriptRedactedActive: String = ""

    // MARK: Reflection / tools output (stored locally)

    /// Legacy single-output field (kept for backward compatibility).
    /// Prefer the per-tool fields below.
    var reflectionText: String = ""

    // Reflect
    var reflectText: String?
    var reflectPromptVersion: String?
    var reflectUpdatedAt: Date?

    // Perspective
    var perspectiveText: String?
    var perspectivePromptVersion: String?
    var perspectiveUpdatedAt: Date?

    // Options
    var optionsText: String?
    var optionsPromptVersion: String?
    var optionsUpdatedAt: Date?

    // Questions
    var questionsText: String?
    var questionsPromptVersion: String?
    var questionsUpdatedAt: Date?

    // Talk it through (multi-turn)
    /// JSON-encoded array of messages for this turn’s thread (local only).
    var talkThreadJSON: Data = Data("[]".utf8)
    /// Last Responses API response_id (continuation token).
    var talkLastResponseID: String?
    var talkPromptVersion: String?
    var talkUpdatedAt: Date?

    // MARK: WAL (local only)

    /// JSON-encoded WAL snapshot (local only).
    var walJSON: Data = Data("{}".utf8)
    var walUpdatedAt: Date?

    /// Default to 0 so new captures don’t look "learned" by default.
    var walVersion: Int = 0

    // MARK: Redaction

    var redactionVersion: Int = 1
    var redactionTimestamp: Date?
    var redactionInputHash: String?

    // MARK: State

    /// Raw persisted state. Use `state` computed property in code.
    var stateRaw: String = TurnState.queued.rawValue

    // MARK: Providers / tooling

    var transcriptionProviderRaw: String = TranscriptionProvider.unknown.rawValue
    var transcriptionLocale: String?

    var reflectProviderRaw: String = ReflectProvider.none.rawValue
    var promptVersion: Int?
    var toolchainVersion: String?
    var capsuleSnapshotHash: String?

    // MARK: Processing lifecycle

    var processingStartedAt: Date?
    var processingFinishedAt: Date?

    // MARK: Error (best-effort diagnostics)

    var errorDomain: String?
    var errorCode: Int?
    var userFacingErrorKey: String?
    var errorDebugMessage: String?

    // MARK: - Initialiser

    init(id: UUID = UUID()) {
        self.id = id
    }
}

// MARK: - Typed accessors (no logic, no side effects)

extension TurnEntity {

    var state: TurnState {
        get { TurnState(rawValue: stateRaw) ?? .queued }
        set { stateRaw = newValue.rawValue }
    }

    var captureContext: CaptureContext {
        get { CaptureContext(rawValue: captureContextRaw) ?? .unknown }
        set { captureContextRaw = newValue.rawValue }
    }

    var transcriptionProvider: TranscriptionProvider {
        get { TranscriptionProvider(rawValue: transcriptionProviderRaw) ?? .unknown }
        set { transcriptionProviderRaw = newValue.rawValue }
    }

    var reflectProvider: ReflectProvider {
        get { ReflectProvider(rawValue: reflectProviderRaw) ?? .none }
        set { reflectProviderRaw = newValue.rawValue }
    }

    /// True only if the user explicitly named this capture.
    var hasManualTitle: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - WAL signal helpers (computed, migration-safe)

extension TurnEntity {

    /// UI signal only: do we have a non-empty WAL payload blob?
    /// This avoids “always on” behaviour.
    var hasLearnedCues: Bool {
        let s = String(data: walJSON, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !s.isEmpty && s != "{}" && s != "null"
    }
}

// MARK: - RedactionRecordEntity

@Model
final class RedactionRecordEntity {

    @Attribute(.unique)
    var id: UUID

    var turnId: UUID
    var version: Int
    var timestamp: Date
    var inputHash: String
    var textRedacted: String

    init(
        id: UUID = UUID(),
        turnId: UUID,
        version: Int,
        timestamp: Date,
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

// MARK: - CapsuleEntity (singleton persistence)

@Model
final class CapsuleEntity {

    /// Always `"singleton"`
    @Attribute(.unique)
    var id: String

    var version: Int
    var learningEnabled: Bool
    var updatedAt: Date

    var preferencesJSON: Data
    var learnedJSON: Data

    init() {
        self.id = "singleton"
        self.version = 1
        self.learningEnabled = true
        self.updatedAt = Date()
        self.preferencesJSON = Data()
        self.learnedJSON = Data()
    }
}

// MARK: - PatternStatsEntity (Learning; add-only schema)

@Model
final class PatternStatsEntity {

    @Attribute(.unique)
    var id: UUID

    // Kind of pattern (allowed: style_preference, workflow_preference, topic_recurrence, resolution_pattern, constraints_sensitivity, narrative_pattern, lens_preference, constraint_trigger, contraction_pattern, release_pattern)
    var kindRaw: String

    // Pattern key (e.g., "bullets", "concise", "options_first", "topic:taxes")
    var key: String

    // Decayed score (0...1 or any non-negative real); we’ll keep Double flexible
    var score: Double

    // Observed count (integer, bounded)
    var count: Int

    // First and last observation timestamps
    var firstSeenAt: Date
    var lastSeenAt: Date

    // Decay control (days)
    var halfLifeDays: Double

    init(
        id: UUID = UUID(),
        kindRaw: String,
        key: String,
        score: Double = 0,
        count: Int = 0,
        firstSeenAt: Date = Date(),
        lastSeenAt: Date = Date(),
        halfLifeDays: Double = 14.0
    ) {
        self.id = id
        self.kindRaw = kindRaw
        self.key = key
        self.score = score
        self.count = count
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.halfLifeDays = halfLifeDays
    }
}

extension PatternStatsEntity {
    enum Kind: String, CaseIterable {
        case style_preference
        case workflow_preference
        case topic_recurrence
        case resolution_pattern
        case constraints_sensitivity
        case narrative_pattern
        case lens_preference
        case constraint_trigger
        case contraction_pattern
        case release_pattern
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .style_preference }
        set { kindRaw = newValue.rawValue }
    }
}
