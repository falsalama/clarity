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

    var redactionVersion: Int
    var redactionTimestamp: Date?
    var redactionInputHash: String?

    var state: TurnState

    var transcriptionProvider: TranscriptionProvider
    var transcriptionLocale: String?

    var reflectProvider: ReflectProvider
    var promptVersion: Int?
    var toolchainVersion: String?
    var capsuleSnapshotHash: String?

    var processingStartedAt: Date?
    var processingFinishedAt: Date?

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

