// SwiftDataModels.swift
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
    var walVersion: Int = 1

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

