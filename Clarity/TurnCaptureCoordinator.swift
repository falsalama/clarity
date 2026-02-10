// TurnCaptureCoordinator.swift

import Foundation
import SwiftData
import Combine
import SwiftUI
#if os(iOS)
import UIKit
#endif

@MainActor
final class TurnCaptureCoordinator: ObservableObject {

    enum Phase: Equatable {
        case idle
        case preparing
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

    // Prevent duplicate learning updates for the same turn if transcripts arrive more than once
    private var learnedTurnIDs: Set<UUID> = []

    // Post-stop pipeline control
    private var postStopTask: Task<Void, Never>?
    private var isPostStopActive: Bool = false
    private let dwellFinalisingSeconds: Double = 1.0
    private let dwellTranscribingSeconds: Double = 1.0

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

        case .inactive:
            // Siri handoff / overlays often flip the app to .inactive briefly.
            // Do NOT stop capture on .inactive or Siri-start will "blink off".
            return

        case .background:
            stopIfNeededForLifecycle()

        @unknown default:
            stopIfNeededForLifecycle()
        }
    }

    private func stopIfNeededForLifecycle() {
        guard !isStoppingForLifecycle else { return }

        stopIdleGuard()
        setIdleTimerDisabled(false)

        switch phase {
        case .idle:
            return
        case .preparing, .recording:
            isStoppingForLifecycle = true
            stopCapture()
        case .finalising, .transcribing, .redacting:
            isStoppingForLifecycle = true
            recorder.stop()
            if transcriber.isTranscribing { transcriber.stop() }
            phase = .idle
            isPostStopActive = false
        }
    }

    func toggleCapture() {
        switch phase {
        case .idle:
            startCapture()
        case .recording:
            stopCapture()
        case .preparing, .finalising, .transcribing, .redacting:
            break
        }
    }

    func startCapture() {
        // Kill any lingering post-stop pipeline first.
        postStopTask?.cancel()
        postStopTask = nil
        isPostStopActive = false

        // If we’re not idle (e.g., stuck in processing UI), force-reset to idle.
        if phase != .idle {
            recorder.stop()
            if transcriber.isTranscribing { transcriber.cancel() }
            phase = .idle
        }

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

        // Do NOT set .preparing for real capture; keep UI as-is until recording is actually live.
        setIdleTimerDisabled(true)
        startIdleGuard()

        Task { @MainActor in
            await Task.yield()

            let ok = await transcriber.startSession()
            guard ok else {
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
        // Allow stop from preparing or recording.
        guard phase == .recording || phase == .preparing else { return }
        // If already in post-stop, ignore duplicate taps.
        guard !isPostStopActive else { return }
        isPostStopActive = true

        // Freeze interim UI updates immediately
        transcriber.resetUI()
        liveTranscript = ""

        // Immediately move UI away from "Recording"
        phase = .finalising

        // Immediately stop engines to avoid tail updates and reduce blink risk
        recorder.stop()
        transcriber.stop()

        // Start the post-stop pipeline right away (single owner)
        startPostStopPipeline()

        // If we never created a turn (recording never truly started), clear pending URL.
        if activeTurnID == nil {
            pendingCaptureURL = nil
        }
    }

    func clearLiveTranscript() {
        transcriber.hardResetAll()
        liveTranscript = ""
    }

    // NEW: collapse any non-recording processing state back to idle (used on view disappear)
    func forceIdleIfProcessing() {
        // Only act if we are not actively recording
        guard phase != .recording else { return }

        // Cancel post-stop pipeline
        postStopTask?.cancel()
        postStopTask = nil
        isPostStopActive = false

        // Stop recorder/transcriber best-effort
        recorder.stop()
        if transcriber.isTranscribing {
            transcriber.cancel()
        }

        // Clear transient capture state
        activeTurnID = nil
        pendingCaptureURL = nil
        lastHandledFilePath = nil
        isHandlingFileURL = false

        // Reset UI-related guards
        stopIdleGuard()
        setIdleTimerDisabled(false)

        // Clear any transient UI errors for a clean return
        uiError = nil
        lastError = nil

        // Return to idle
        phase = .idle
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
                guard let self else { return }
                // Suppress late live updates during post-stop
                if self.isPostStopActive { return }
                self.liveTranscript = text
            }
            .store(in: &cancellables)

        transcriber.$lastTranscript
            .receive(on: RunLoop.main)
            .sink { [weak self] raw in
                // This is the “final” streaming transcript result; allow it, post-stop or not.
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
        guard !isHandlingFileURL else { return }

        let path = url.path
        guard lastHandledFilePath != path else { return }
        lastHandledFilePath = path

        pendingCaptureURL = url
    }

    private func handleRecorderRecordingChanged(_ isRecording: Bool) {
        // Ignore any recorder state once post-stop pipeline has started.
        if isPostStopActive { return }

        setIdleTimerDisabled(isRecording)

        if isRecording {
            if phase != .recording { phase = .recording }
            startIdleGuard()
            createTurnIfNeededNowThatRecordingIsLive()
            postStopTask?.cancel()
            postStopTask = nil
            return
        }

        // Engine stopped without our explicit stop; start post-stop pipeline.
        if phase == .recording || phase == .preparing {
            stopCapture()
        }
    }

    private func startPostStopPipeline() {
        postStopTask?.cancel()
        postStopTask = Task { @MainActor in
            // Ensure finalising and stop the idle guard (idempotent)
            self.phase = .finalising
            self.stopIdleGuard()

            // Dwell in Finalising
            let finalisingNanos = UInt64((self.dwellFinalisingSeconds * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: finalisingNanos)

            // Move to Transcribing and dwell there
            self.phase = .transcribing

            let transcribingNanos = UInt64((self.dwellTranscribingSeconds * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: transcribingNanos)
            // Remain in .transcribing until transcript/error arrives.
        }
    }

    private func createTurnIfNeededNowThatRecordingIsLive() {
        guard activeTurnID == nil else { return }
        guard let repo else { return }
        guard let url = pendingCaptureURL else { return }

        let path = url.path
        guard FileManager.default.fileExists(atPath: path) else { return }

        let stored = FileStore.storedAudioPath(forFilename: url.lastPathComponent)

        do {
            activeTurnID = try repo.createCaptureTurn(audioPath: stored)
        } catch {
            setError(.couldntStartCapture, debug: "createCaptureTurn failed: \(error.localizedDescription)")
            activeTurnID = nil
        }
    }

    private func handleTranscriptArrived(_ raw: String?) {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let id = activeTurnID, let repo, let dictionary else {
            isPostStopActive = false
            phase = .idle
            stopIdleGuard()
            setIdleTimerDisabled(false)
            activeTurnID = nil
            pendingCaptureURL = nil
            return
        }

        // Conclude the pipeline deterministically
        postStopTask?.cancel()
        postStopTask = nil

        phase = .redacting

        let redacted = Redactor(tokens: dictionary.tokens).redact(raw).redactedText
        let titleSource = redacted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? raw : redacted
        let autoTitle = Self.autoTitle(from: titleSource)

        do {
            try repo.markReady(
                id: id,
                endedAt: Date(),
                transcriptRaw: raw,
                transcriptRedactedActive: redacted,
                redactionVersion: 1,
                redactionTimestamp: Date(),
                titleIfAuto: autoTitle
            )

            let now = Date()
            let validated = WALBuilder.buildValidated(from: redacted, now: now)
            try repo.updateWAL(id: id, snapshot: validated)

            if let context = self.modelContext,
               let store = self.capsuleStore,
               store.capsule.learningEnabled,
               learnedTurnIDs.contains(id) == false
            {
                let learner = PatternLearner()
                let observations = learner.deriveObservations(from: validated, redactedText: redacted)
                try learner.apply(observations: observations, into: context, now: now)

                learnedTurnIDs.insert(id)
                LearningSync.sync(context: context, capsuleStore: store, now: now)
            }

            lastCompletedTurnID = id
            lastCompletionAt = Date()

            clearErrors()

            transcriber.resetUI()
            liveTranscript = ""

            runFileTranscriptionBackfill(for: id)
        } catch {
            setError(.couldntSaveTranscript, debug: "markReady failed: \(error.localizedDescription)")
            try? repo.markFailed(id: id, debug: lastError ?? "")
        }

        // Reset per-capture state so a quick new capture can start cleanly.
        activeTurnID = nil
        pendingCaptureURL = nil

        isPostStopActive = false
        // Intentionally do NOT set phase = .idle here to avoid a “Ready” blink
        // while the UI begins navigation to the capture page. Let the view call
        // forceIdleIfProcessing() on disappear to return to idle cleanly.
        stopIdleGuard()
        setIdleTimerDisabled(false)
    }

    private func handleTranscriptionError(_ message: String) {
        // Conclude the pipeline deterministically.
        postStopTask?.cancel()
        postStopTask = nil

        if message == "No transcript captured.",
           let t = lastCompletionAt,
           Date().timeIntervalSince(t) < 3.0 {
            activeTurnID = nil
            pendingCaptureURL = nil

            isPostStopActive = false
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

        activeTurnID = nil
        pendingCaptureURL = nil

        isPostStopActive = false
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

        let url: URL?
        if let u = pendingCaptureURL {
            url = u
        } else if let t = try? repo.fetch(id: id), let stored = t.audioPath, !stored.isEmpty {
            url = FileStore.existingAudioURL(from: stored)
        } else {
            url = nil
        }
        guard let audioURL = url else { return }

        Task { @MainActor in
            do {
                let fullText = try await transcriber.transcribeFile(at: audioURL, onDevicePreferred: false)
                guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

                guard let t = try repo.fetch(id: id) else { return }
                if t.transcriptRaw == fullText { return }

                let redacted = Redactor(tokens: dictionary.tokens).redact(fullText).redactedText
                t.transcriptRaw = fullText
                t.transcriptRedactedActive = redacted
                t.redactionTimestamp = Date()
                t.redactionVersion = max(t.redactionVersion, 1)

                let validated = WALBuilder.buildValidated(from: redacted, now: Date())
                try repo.updateWAL(id: id, snapshot: validated)

                try modelContext?.save()
            } catch {
                // best-effort
            }
        }
    }

    // MARK: - Idle timer (iOS only)

    private func startIdleGuard() {
        idleGuardTask?.cancel()
        idleGuardTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                await MainActor.run {
                    guard let self else { return }
                    if self.phase == .recording || self.phase == .preparing {
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

        // Silent, background warm-up: do not alter UI phase.
        // Keep it short; cancel immediately if a real capture starts.
        let ok = await transcriber.startSession(timeoutSeconds: 3)
        guard ok else {
            hasWarmedUp = true
            return
        }

        // Brief dwell to let recognizer spin up.
        do { try await Task.sleep(nanoseconds: 700_000_000) } catch { }

        // If a real capture started while warming up, don't override/cancel it.
        if phase == .recording || phase == .transcribing || phase == .redacting || phase == .finalising {
            hasWarmedUp = true
            return
        }

        transcriber.cancel()
        hasWarmedUp = true
    }
}

