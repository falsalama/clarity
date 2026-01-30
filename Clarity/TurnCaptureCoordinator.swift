import Foundation
import SwiftData
import Combine
import SwiftUI

@MainActor
final class TurnCaptureCoordinator: ObservableObject {

    // MARK: - Types

    enum Phase: Equatable {
        case idle
        case recording
        case finalising
        case transcribing
        case redacting
    }

    // MARK: - Published (UI-facing)

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var liveTranscript: String = ""
    @Published private(set) var level: Double = 0
    @Published private(set) var lastError: String? = nil

    // NEW: navigation + CarPlay gating
    @Published var lastCompletedTurnID: UUID? = nil
    @Published var isCarPlayConnected: Bool = false

    // MARK: - Dependencies (bound after SwiftData exists)

    private var modelContext: ModelContext?
    private var dictionary: RedactionDictionary?
    private var repo: TurnRepository?

    // MARK: - Engines

    private let recorder = AudioRecorder()
    private let transcriber = SpeechTranscriber()

    // MARK: - Capture state

    private var activeTurnID: UUID?
    private var lastHandledFilePath: String?
    private var isHandlingFileURL: Bool = false

    // Prevent double-stop sequences from scene events + UI stop button.
    private var isStoppingForLifecycle: Bool = false

    // MARK: - Combine

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init() {}

    /// Bind SwiftData + Redaction dictionary once the view tree has a valid ModelContext.
    /// Safe to call multiple times.
    func bind(modelContext: ModelContext, dictionary: RedactionDictionary) {
        self.modelContext = modelContext
        self.dictionary = dictionary
        self.repo = TurnRepository(context: modelContext)
        wireIfNeeded()
    }

    // MARK: - Lifecycle

    /// Call from a view observing scenePhase.
    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            isStoppingForLifecycle = false
        case .inactive, .background:
            stopIfNeededForLifecycle()
        @unknown default:
            stopIfNeededForLifecycle()
        }
    }

    private func stopIfNeededForLifecycle() {
        guard !isStoppingForLifecycle else { return }

        // If we’re mid-recording/transcribing, stop cleanly.
        switch phase {
        case .idle:
            return
        case .recording:
            isStoppingForLifecycle = true
            stopCapture()
        case .finalising, .transcribing, .redacting:
            // Best-effort: ensure engines are stopped so we don’t keep resources alive.
            isStoppingForLifecycle = true
            recorder.stop()
            if transcriber.isTranscribing { transcriber.stop() }
            phase = .idle
        }
    }

    // MARK: - Public controls

    func toggleCapture() {
        switch phase {
        case .idle:
            startCapture()
        case .recording:
            stopCapture()
        case .finalising, .transcribing, .redacting:
            break
        }
    }

    func startCapture() {
        guard phase == .idle else { return }
        guard repo != nil, dictionary != nil else {
            lastError = "Capture not ready."
            return
        }

        isStoppingForLifecycle = false
        lastError = nil
        activeTurnID = nil
        lastHandledFilePath = nil
        isHandlingFileURL = false

        // Keep transcript visible until a new capture begins.
        transcriber.resetUI()

        if transcriber.isTranscribing {
            transcriber.cancel()
        }

        phase = .recording

        Task { @MainActor in
            let ok = await transcriber.startSession()
            guard ok else {
                phase = .idle
                return
            }

            // Attach first, then start audio so we never miss the first buffer.
            transcriber.attach(to: recorder)
            recorder.start()
        }
    }

    func stopCapture() {
        guard phase == .recording else { return }

        phase = .finalising
        recorder.stop()

        phase = .transcribing
        transcriber.stop()
    }

    /// Clears only the on-screen transcript (does not touch stored captures).
    func clearLiveTranscript() {
        transcriber.hardResetAll()
        liveTranscript = ""
    }


    // MARK: - Wiring

    private func wireIfNeeded() {
        guard cancellables.isEmpty else { return }

        recorder.$level
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.level = $0 }
            .store(in: &cancellables)

        recorder.$lastFileURL
            .compactMap { $0 }
            .removeDuplicates(by: { $0.path == $1.path })
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                self?.handleRecorderFileURL(url)
            }
            .store(in: &cancellables)

        recorder.$isRecording
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isRec in
                self?.handleRecorderRecordingChanged(isRec)
            }
            .store(in: &cancellables)

        recorder.$lastError
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] msg in
                self?.lastError = msg
            }
            .store(in: &cancellables)

        transcriber.$liveTranscript
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.liveTranscript = text
            }
            .store(in: &cancellables)

        transcriber.$lastTranscript
            .receive(on: RunLoop.main)
            .sink { [weak self] raw in
                self?.handleTranscriptArrived(raw)
            }
            .store(in: &cancellables)

        transcriber.$lastError
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] msg in
                self?.handleTranscriptionError(msg)
            }
            .store(in: &cancellables)
    }

    // MARK: - Recorder events

    private func handleRecorderFileURL(_ url: URL) {
        guard activeTurnID == nil else { return }
        guard !isHandlingFileURL else { return }

        let path = url.path
        guard lastHandledFilePath != path else { return }
        lastHandledFilePath = path

        guard let repo else { return }

        isHandlingFileURL = true
        defer { isHandlingFileURL = false }

        do {
            let id = try repo.createCaptureTurn(audioPath: path)
            activeTurnID = id
        } catch {
            lastError = "Couldn’t start capture."
            activeTurnID = nil
        }
    }

    private func handleRecorderRecordingChanged(_ isRecording: Bool) {
        if isRecording {
            if phase != .recording { phase = .recording }
            return
        }

        if phase == .recording {
            phase = .transcribing
        }
    }

    // MARK: - Transcription events

    private func handleTranscriptArrived(_ raw: String?) {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let id = activeTurnID else { phase = .idle; return }
        guard let repo, let dictionary else { phase = .idle; return }

        phase = .redacting

        let redacted = Redactor(tokens: dictionary.tokens).redact(raw).redactedText
        let titleSource = redacted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? raw : redacted
        let autoTitle = Self.autoTitle(from: titleSource)

        do {
            try repo.markReady(
                id: id,
                transcriptRaw: raw,
                transcriptRedactedActive: redacted,
                redactionVersion: 1,
                redactionTimestamp: Date(),
                titleIfAuto: autoTitle
            )

            // NEW: signal completion for UI navigation (iPhone/iPad/Mac)
            lastCompletedTurnID = id

            // NEW: reset transient capture UI now that the capture has been committed
            transcriber.resetUI()
            liveTranscript = ""
        } catch {
            lastError = "Couldn’t save transcript."
            try? repo.markFailed(id: id, debug: "save transcript failed")
        }

        phase = .idle
    }

    private func handleTranscriptionError(_ message: String) {
        lastError = message
        if let id = activeTurnID, let repo {
            try? repo.markFailed(id: id, debug: message)

            // Navigate only when mic was allowed/working, audio actually recorded,
            // but no speech was recognized (protects against pocket presses and permission errors).
            if message == "No transcript captured." {
                let dur = recorder.lastDurationSeconds
                if dur >= 0.5 {
                    lastCompletedTurnID = id
                }
            }
        }
        phase = .idle
    }

    // MARK: - Title helper

    private static func autoTitle(from text: String) -> String? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        guard !cleaned.isEmpty else { return nil }

        let words = cleaned.split(whereSeparator: \.isWhitespace).prefix(7).map(String.init)
        let title = words.joined(separator: " ")
        let capped = String(title.prefix(56))
        return capped.isEmpty ? nil : capped
    }
}
