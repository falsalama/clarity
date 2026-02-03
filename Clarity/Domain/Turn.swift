// Turn.swift
import Foundation

struct Turn: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var source: TurnSource
    var recordedAt: Date
    var endedAt: Date?
    var durationSeconds: Double?
    var sourceOriginalDate: Date?
    var captureContext: CaptureContext

    var title: String

    var audioPath: String?
    var audioBytes: Int64?

    // Local-only; never leaves device unless user explicitly exports.
    var transcriptRaw: String?

    // Canonical display + any cloud payload
    var transcriptRedactedActive: String

    // MARK: - Tool outputs (local only)

    // Legacy single-output field (kept for backward compatibility).
    // Prefer the per-tool fields below.
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
    var talkThreadJSON: Data
    /// Last Responses API response_id (continuation token).
    var talkLastResponseID: String?
    var talkPromptVersion: String?
    var talkUpdatedAt: Date?

    // MARK: - WAL (local only)

    /// JSON-encoded WAL snapshot (local only). Keep this small.
    var walJSON: Data
    var walUpdatedAt: Date?
    var walVersion: Int

    // MARK: - Redaction

    var redactionVersion: Int
    var redactionTimestamp: Date?
    var redactionInputHash: String?

    // MARK: - State

    var state: TurnState

    // MARK: - Providers / tooling

    var transcriptionProvider: TranscriptionProvider
    var transcriptionLocale: String?

    var reflectProvider: ReflectProvider
    var promptVersion: Int?
    var toolchainVersion: String?
    var capsuleSnapshotHash: String?

    // MARK: - Processing lifecycle

    var processingStartedAt: Date?
    var processingFinishedAt: Date?

    // MARK: - Error

    var error: TurnError?

    init(
        id: UUID = UUID(),
        source: TurnSource = .captured,
        recordedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Double? = nil,
        sourceOriginalDate: Date? = nil,
        captureContext: CaptureContext = .unknown,
        title: String = "Untitled",
        audioPath: String? = nil,
        audioBytes: Int64? = nil,
        transcriptRaw: String? = nil,
        transcriptRedactedActive: String = "",

        // Tool outputs
        reflectionText: String = "",
        reflectText: String? = nil,
        reflectPromptVersion: String? = nil,
        reflectUpdatedAt: Date? = nil,

        perspectiveText: String? = nil,
        perspectivePromptVersion: String? = nil,
        perspectiveUpdatedAt: Date? = nil,

        optionsText: String? = nil,
        optionsPromptVersion: String? = nil,
        optionsUpdatedAt: Date? = nil,

        questionsText: String? = nil,
        questionsPromptVersion: String? = nil,
        questionsUpdatedAt: Date? = nil,

        talkThreadJSON: Data = Data("[]".utf8),
        talkLastResponseID: String? = nil,
        talkPromptVersion: String? = nil,
        talkUpdatedAt: Date? = nil,

        // WAL
        walJSON: Data = Data("{}".utf8),
        walUpdatedAt: Date? = nil,
        walVersion: Int = 1,

        // Redaction / state / tooling
        redactionVersion: Int = 1,
        redactionTimestamp: Date? = nil,
        redactionInputHash: String? = nil,
        state: TurnState = .queued,
        transcriptionProvider: TranscriptionProvider = .unknown,
        transcriptionLocale: String? = nil,
        reflectProvider: ReflectProvider = .none,
        promptVersion: Int? = nil,
        toolchainVersion: String? = nil,
        capsuleSnapshotHash: String? = nil,
        processingStartedAt: Date? = nil,
        processingFinishedAt: Date? = nil,
        error: TurnError? = nil
    ) {
        self.id = id
        self.source = source
        self.recordedAt = recordedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.sourceOriginalDate = sourceOriginalDate
        self.captureContext = captureContext

        self.title = title

        self.audioPath = audioPath
        self.audioBytes = audioBytes

        self.transcriptRaw = transcriptRaw
        self.transcriptRedactedActive = transcriptRedactedActive

        self.reflectionText = reflectionText

        self.reflectText = reflectText
        self.reflectPromptVersion = reflectPromptVersion
        self.reflectUpdatedAt = reflectUpdatedAt

        self.perspectiveText = perspectiveText
        self.perspectivePromptVersion = perspectivePromptVersion
        self.perspectiveUpdatedAt = perspectiveUpdatedAt

        self.optionsText = optionsText
        self.optionsPromptVersion = optionsPromptVersion
        self.optionsUpdatedAt = optionsUpdatedAt

        self.questionsText = questionsText
        self.questionsPromptVersion = questionsPromptVersion
        self.questionsUpdatedAt = questionsUpdatedAt

        self.talkThreadJSON = talkThreadJSON
        self.talkLastResponseID = talkLastResponseID
        self.talkPromptVersion = talkPromptVersion
        self.talkUpdatedAt = talkUpdatedAt

        self.walJSON = walJSON
        self.walUpdatedAt = walUpdatedAt
        self.walVersion = walVersion

        self.redactionVersion = redactionVersion
        self.redactionTimestamp = redactionTimestamp
        self.redactionInputHash = redactionInputHash

        self.state = state

        self.transcriptionProvider = transcriptionProvider
        self.transcriptionLocale = transcriptionLocale

        self.reflectProvider = reflectProvider
        self.promptVersion = promptVersion
        self.toolchainVersion = toolchainVersion
        self.capsuleSnapshotHash = capsuleSnapshotHash

        self.processingStartedAt = processingStartedAt
        self.processingFinishedAt = processingFinishedAt

        self.error = error
    }
}

