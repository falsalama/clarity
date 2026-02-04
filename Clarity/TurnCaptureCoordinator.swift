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

    // Hold URL until we know recording really started
    private var pendingCaptureURL: URL?

    // Idle timer guard (keeps reasserting while recording)
    private var idleGuardTask: Task<Void, Never>?

    // One-time recognizer warm-up per app session
    private var hasWarmedUp: Bool = false
    private var warmUpTask: Task<Void, Never>?

    init() {}

    func bind(modelContext: ModelContext, dictionary: RedactionDictionary, capsuleStore: CapsuleStore) {
        self.modelContext = modelContext
        self.dictionary = dictionary
        self.capsuleStore = capsuleStore
        self.repo = TurnRepository(context: modelContext)
        wireIfNeeded()

        // Eager, one-time warm-up so first real capture isn't truncated.
        if !hasWarmedUp {
            warmUpTask?.cancel()
            warmUpTask = Task { [weak self] in
                await self?.warmUpIfNeeded()
            }
        }
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

        // Always restore idle on lifecycle stop
        stopIdleGuard()
        setIdleTimerDisabled(false)

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

        // If a warm-up is in progress, cancel it immediately to prioritise real capture.
        warmUpTask?.cancel()
        warmUpTask = nil

        clearErrors()
        isStoppingForLifecycle = false

        activeTurnID = nil
        lastHandledFilePath = nil
        isHandlingFileURL = false
        lastCompletionAt = nil
        pendingCaptureURL = nil

        if transcriber.isTranscribing { transcriber.cancel() }

        // Enter recording phase and immediately assert idle disabled.
        phase = .recording
        setIdleTimerDisabled(true)
        startIdleGuard()

        Task { @MainActor in
            let ok = await transcriber.startSession()
            guard ok else {
                // Failed to start speech; leave recording flow and restore idle.
                stopIdleGuard()
                setIdleTimerDisabled(false)
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
            stopIdleGuard()
            setIdleTimerDisabled(false)
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
        // Mirror the device state promptly.
        setIdleTimerDisabled(isRecording)
        if isRecording {
            // Now we know the engine actually started.
            if phase != .recording { phase = .recording }
            startIdleGuard()
            createTurnIfNeededNowThatRecordingIsLive()
            return
        }

        // Recording stopped. Move to transcribing (unless already finished)
        if phase == .finalising || phase == .recording {
            phase = .transcribing
            stopIdleGuard()
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
            stopIdleGuard()
            setIdleTimerDisabled(false)
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

            // Build validated WAL unconditionally and always persist locally.
            let now = Date()
            let validated = WALBuilder.buildValidated(from: redacted, now: now)
            try repo.updateWAL(id: id, snapshot: validated)

            // Derive and apply learning observations only when learning is enabled.
            if let context = self.modelContext, let store = self.capsuleStore, store.capsule.learningEnabled {
                let learner = PatternLearner()
                let observations = learner.deriveObservations(from: validated, redactedText: redacted)
                try learner.apply(observations: observations, into: context, now: now)

                // Bridge to Capsule: project PatternStats -> Capsule.learnedTendencies (one-way)
                LearningSync.sync(context: context, capsuleStore: store, now: now)
            }

            lastCompletedTurnID = id
            lastCompletionAt = Date()

            clearErrors()

            transcriber.resetUI()
            liveTranscript = ""

            // Kick off a full file-based pass to ensure long recordings are fully transcribed.
            runFileTranscriptionBackfill(for: id)
        } catch {
            setError(.couldntSaveTranscript, debug: "markReady failed: \(error.localizedDescription)")
            try? repo.markFailed(id: id, debug: lastError ?? "")
        }

        phase = .idle
        stopIdleGuard()
        setIdleTimerDisabled(false)
    }

    private func handleTranscriptionError(_ message: String) {
        if message == "No transcript captured.",
           let t = lastCompletionAt,
           Date().timeIntervalSince(t) < 3.0 {
            phase = .idle
            stopIdleGuard()
            setIdleTimerDisabled(false)
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
        stopIdleGuard()
        setIdleTimerDisabled(false)
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

    // MARK: - Full file backfill

    private func runFileTranscriptionBackfill(for id: UUID) {
        guard let repo, let dictionary else { return }

        // Resolve audio URL
        let url: URL?
        if let u = pendingCaptureURL {
            url = u
        } else if let t = try? repo.fetch(id: id), let path = t.audioPath, !path.isEmpty {
            url = URL(fileURLWithPath: path)
        } else {
            url = nil
        }
        guard let audioURL = url else { return }

        Task { @MainActor in
            do {
                let fullText = try await transcriber.transcribeFile(at: audioURL, onDevicePreferred: false)
                guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

                // If unchanged, skip
                guard let t = try repo.fetch(id: id) else { return }
                if t.transcriptRaw == fullText { return }

                // Replace transcript with full-pass result
                let redacted = Redactor(tokens: dictionary.tokens).redact(fullText).redactedText
                t.transcriptRaw = fullText
                t.transcriptRedactedActive = redacted
                t.redactionTimestamp = Date()
                t.redactionVersion = max(t.redactionVersion, 1)

                // Rebuild WAL snapshot (local only); avoid re-applying learning to prevent double counting.
                let validated = WALBuilder.buildValidated(from: redacted, now: Date())
                try repo.updateWAL(id: id, snapshot: validated)

                try modelContext?.save()
            } catch {
                // Silent: backfill is best-effort
            }
        }
    }

    // MARK: - Idle timer (iOS only)

    private func startIdleGuard() {
        // Cancel any previous guard
        idleGuardTask?.cancel()
        idleGuardTask = Task { [weak self] in
            // Reassert every ~20s (shorter than typical auto-lock values), while recording.
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                await MainActor.run {
                    guard let self else { return }
                    if self.phase == .recording {
                        self.setIdleTimerDisabled(true)
                    } else {
                        self.idleGuardTask?.cancel()
                        self.idleGuardTask = nil
                    }
                }
            }
        }
    }

    private func stopIdleGuard() {
        idleGuardTask?.cancel()
        idleGuardTask = nil
    }

    @MainActor
    private func setIdleTimerDisabled(_ disabled: Bool) {
#if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = disabled
#endif
    }

    // MARK: - One-time warm-up

    private func warmUpIfNeeded() async {
        guard !hasWarmedUp else { return }

        // Start a short, hidden session to prime recognizer and audio paths.
        let ok = await transcriber.startSession(timeoutSeconds: 5)
        guard ok else {
            hasWarmedUp = true // avoid retry loops; we can revisit if needed
            return
        }

        // No need to attach the recorder; we just want the recognizer spun up.
        // Wait briefly to allow model initialisation.
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000) // ~1.5s
        } catch { }

        // If a real capture started meanwhile, transcriber might already be in use; bail safely.
        if phase == .recording || phase == .transcribing || phase == .redacting {
            hasWarmedUp = true
            return
        }

        transcriber.cancel()
        hasWarmedUp = true
    }
}
