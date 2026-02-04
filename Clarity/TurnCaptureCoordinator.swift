import Foundation
import SwiftData
import Combine
import SwiftUI

@MainActor
final class TurnCaptureCoordinator: ObservableObject {

    enum Phase: Equatable {
        case idle
        case recording
        case finalising
        case transcribing
        case redacting
    }

    enum UIError: Equatable {
        case notReady

        // Permissions (handled via alert in UI)
        case micDenied
        case micNotGranted
        case speechDeniedOrNotAuthorised
        case speechUnavailable

        // Capture/persistence
        case couldntStartCapture
        case couldntSaveTranscript
        case noTranscriptCaptured

        case unknown
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var liveTranscript: String = ""
    @Published private(set) var level: Double = 0

    // Debug only (never show directly)
    @Published private(set) var lastError: String? = nil

    // Stable UI error for views
    @Published private(set) var uiError: UIError? = nil

    @Published var lastCompletedTurnID: UUID? = nil
    @Published var isCarPlayConnected: Bool = false

    private var modelContext: ModelContext?
    private var dictionary: RedactionDictionary?
    private var capsuleStore: CapsuleStore?
    private var repo: TurnRepository?

    private let recorder = AudioRecorder()
    private let transcriber = SpeechTranscriber()

    private var activeTurnID: UUID?
    private var lastHandledFilePath: String?
    private var isHandlingFileURL = false
    private var isStoppingForLifecycle = false

    private var cancellables: Set<AnyCancellable> = []

    // Ignore late/duplicate simulator errors
    private var lastCompletionAt: Date?

    // NEW: hold URL until we know recording really started
    private var pendingCaptureURL: URL?

    init() {}

    func bind(modelContext: ModelContext, dictionary: RedactionDictionary, capsuleStore: CapsuleStore) {
        self.modelContext = modelContext
        self.dictionary = dictionary
        self.capsuleStore = capsuleStore
        self.repo = TurnRepository(context: modelContext)
        wireIfNeeded()
    }

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

        switch phase {
        case .idle:
            return
        case .recording:
            isStoppingForLifecycle = true
            stopCapture()
        case .finalising, .transcribing, .redacting:
            isStoppingForLifecycle = true
            recorder.stop()
            if transcriber.isTranscribing { transcriber.stop() }
            phase = .idle
        }
    }

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
            setError(.notReady, debug: "Capture not ready.")
            return
        }

        clearErrors()
        isStoppingForLifecycle = false

        activeTurnID = nil
        lastHandledFilePath = nil
        isHandlingFileURL = false
        lastCompletionAt = nil
        pendingCaptureURL = nil

        if transcriber.isTranscribing { transcriber.cancel() }

        phase = .recording

        Task { @MainActor in
            let ok = await transcriber.startSession()
            guard ok else {
                phase = .idle
                return
            }

            transcriber.resetUI()
            transcriber.attach(to: recorder)
            recorder.start()
        }
    }

    func stopCapture() {
        guard phase == .recording else { return }

        phase = .finalising
        recorder.stop()

        if transcriber.isTranscribing {
            phase = .transcribing
            transcriber.stop()
        } else {
            phase = .idle
        }

        // If we never created a turn (recording never truly started), clear pending URL.
        if activeTurnID == nil {
            pendingCaptureURL = nil
        }
    }

    func clearLiveTranscript() {
        transcriber.hardResetAll()
        liveTranscript = ""
    }

    private func clearErrors() {
        uiError = nil
        lastError = nil
    }

    private func setError(_ ui: UIError, debug: String) {
        uiError = ui
        lastError = debug
    }

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
                self?.handleRecorderError(msg)
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

    private func handleRecorderError(_ msg: String) {
        let m = msg.lowercased()

        if m.contains("microphone permission denied") {
            setError(.micDenied, debug: msg)
        } else if m.contains("microphone permission not granted") {
            setError(.micNotGranted, debug: msg)
        } else {
            setError(.couldntStartCapture, debug: msg)
        }
    }

    private func handleRecorderFileURL(_ url: URL) {
        // Do NOT create a Turn yet. Just hold onto the URL.
        guard !isHandlingFileURL else { return }

        let path = url.path
        guard lastHandledFilePath != path else { return }
        lastHandledFilePath = path

        pendingCaptureURL = url
    }

    private func handleRecorderRecordingChanged(_ isRecording: Bool) {
        if isRecording {
            // Now we know the engine actually started.
            if phase != .recording { phase = .recording }
            createTurnIfNeededNowThatRecordingIsLive()
            return
        }

        // Recording stopped. Move to transcribing (unless already finished)
        if phase == .finalising || phase == .recording {
            phase = .transcribing
        }
    }

    private func createTurnIfNeededNowThatRecordingIsLive() {
        guard activeTurnID == nil else { return }
        guard let repo else { return }
        guard let url = pendingCaptureURL else { return }

        let path = url.path
        guard FileManager.default.fileExists(atPath: path) else {
            // If the file still doesn't exist, don't create a Turn yet.
            return
        }

        do {
            activeTurnID = try repo.createCaptureTurn(audioPath: path)
        } catch {
            setError(.couldntStartCapture, debug: "createCaptureTurn failed: \(error.localizedDescription)")
            activeTurnID = nil
        }
    }

    private func handleTranscriptArrived(_ raw: String?) {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let id = activeTurnID, let repo, let dictionary else {
            phase = .idle
            return
        }

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

            // C2: Local WAL build (internal flag, non-UI)
            if FeatureFlags.localWALBuildEnabled {
                let lift0 = Lift0Extractor().extract(from: redacted)
                let candidates = PrimitiveCandidateExtractor().extract(from: redacted)
                let topScore = candidates.first?.score
                let selection = PrimitiveCandidateExtractor().selectTop(from: candidates)
                let lenses = LensSelector().select(from: selection.dominant, background: selection.background, topCandidateScore: topScore)
                let validated = WALValidator().validate(
                    lift0: lift0,
                    primitiveDominant: selection.dominant,
                    primitiveBackground: selection.background,
                    candidates: candidates,
                    lenses: lenses,
                    confirmationNeeded: selection.needsConfirmation
                )

                // Persist only the validated snapshot
                try repo.updateWAL(id: id, snapshot: validated)

                // NEW: Derive and apply learning observations (gated, validated-only)
                if let context = self.modelContext, let store = self.capsuleStore, store.capsule.learningEnabled {
                    let learner = PatternLearner()
                    let observations = learner.deriveObservations(from: validated, redactedText: redacted)
                    try learner.apply(observations: observations, into: context, now: Date())

                    // Bridge to Capsule: project PatternStats -> Capsule.learnedTendencies (one-way)
                    LearningSync.sync(context: context, capsuleStore: store, now: Date())
                }
            }

            lastCompletedTurnID = id
            lastCompletionAt = Date()

            clearErrors()

            transcriber.resetUI()
            liveTranscript = ""
        } catch {
            setError(.couldntSaveTranscript, debug: "markReady failed: \(error.localizedDescription)")
            try? repo.markFailed(id: id, debug: lastError ?? "")
        }

        phase = .idle
    }

    private func handleTranscriptionError(_ message: String) {
        if message == "No transcript captured.",
           let t = lastCompletionAt,
           Date().timeIntervalSince(t) < 3.0 {
            phase = .idle
            return
        }

        lastError = message

        let m = message.lowercased()
        if m.contains("speech not authorised") || m.contains("speech not authorized") {
            uiError = .speechDeniedOrNotAuthorised
        } else if m.contains("speech recogniser unavailable") || m.contains("speech recognizer unavailable") {
            uiError = .speechUnavailable
        } else if message == "No transcript captured." {
            uiError = .noTranscriptCaptured
        } else {
            uiError = .unknown
        }

        if let id = activeTurnID, let repo {
            try? repo.markFailed(id: id, debug: message)
        }

        phase = .idle
    }

    private static func autoTitle(from text: String) -> String? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        guard !cleaned.isEmpty else { return nil }

        let words = cleaned
            .split(whereSeparator: \.isWhitespace)
            .prefix(7)
            .map(String.init)

        let title = words.joined(separator: " ")
        let capped = String(title.prefix(56))
        return capped.isEmpty ? nil : capped
    }
}
