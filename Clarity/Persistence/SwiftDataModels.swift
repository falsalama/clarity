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

    var sourceRaw: String
    var recordedAt: Date
    var endedAt: Date?
    var durationSeconds: Double?
    var sourceOriginalDate: Date?

    var captureContextRaw: String

    // MARK: Title

    /// User-editable title. Empty string means "no manual title".
    var title: String

    // MARK: Audio

    var audioPath: String?
    var audioBytes: Int64

    // MARK: Transcript

    /// Local-only, never leaves device unless user explicitly exports.
    var transcriptRaw: String?

    /// Canonical display transcript and any cloud payload.
    var transcriptRedactedActive: String

    // MARK: Reflection / tools output (stored locally)

    /// Legacy single-output field (kept for backward compatibility).
    /// Prefer the per-tool fields below.
    var reflectionText: String

    // Reflect
    var reflectText: String?
    var reflectPromptVersion: String?
    var reflectUpdatedAt: Date?

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
    var talkThreadJSON: Data
    /// Last Responses API response_id (continuation token).
    var talkLastResponseID: String?
    var talkPromptVersion: String?
    var talkUpdatedAt: Date?

    // MARK: Redaction

    var redactionVersion: Int
    var redactionTimestamp: Date?
    var redactionInputHash: String?

    // MARK: State

    /// Raw persisted state. Use `state` computed property in code.
    var stateRaw: String

    // MARK: Providers / tooling

    var transcriptionProviderRaw: String
    var transcriptionLocale: String?

    var reflectProviderRaw: String
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

        self.sourceRaw = TurnSource.captured.rawValue
        self.recordedAt = Date()
        self.endedAt = nil
        self.durationSeconds = nil
        self.sourceOriginalDate = nil

        self.captureContextRaw = CaptureContext.unknown.rawValue

        // Empty title means “no manual title set”
        self.title = ""

        self.audioPath = nil
        self.audioBytes = 0

        self.transcriptRaw = nil
        self.transcriptRedactedActive = ""

        self.reflectionText = ""

        self.reflectText = nil
        self.reflectPromptVersion = nil
        self.reflectUpdatedAt = nil

        self.optionsText = nil
        self.optionsPromptVersion = nil
        self.optionsUpdatedAt = nil

        self.questionsText = nil
        self.questionsPromptVersion = nil
        self.questionsUpdatedAt = nil

        // Use an explicit empty JSON array by default to avoid decode failures later.
        self.talkThreadJSON = Data("[]".utf8)
        self.talkLastResponseID = nil
        self.talkPromptVersion = nil
        self.talkUpdatedAt = nil

        self.redactionVersion = 1
        self.redactionTimestamp = nil
        self.redactionInputHash = nil

        self.stateRaw = TurnState.queued.rawValue

        self.transcriptionProviderRaw = TranscriptionProvider.unknown.rawValue
        self.transcriptionLocale = nil

        self.reflectProviderRaw = ReflectProvider.none.rawValue
        self.promptVersion = nil
        self.toolchainVersion = nil
        self.capsuleSnapshotHash = nil

        self.processingStartedAt = nil
        self.processingFinishedAt = nil

        self.errorDomain = nil
        self.errorCode = nil
        self.userFacingErrorKey = nil
        self.errorDebugMessage = nil
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

