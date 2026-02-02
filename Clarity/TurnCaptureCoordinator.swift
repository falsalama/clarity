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
    private var repo: TurnRepository?

    private let recorder = AudioRecorder()
    private let transcriber = SpeechTranscriber()

    private var activeTurnID: UUID?
    private var lastHandledFilePath: String?
    private var isHandlingFileURL = false
    private var isStoppingForLifecycle = false

    private var cancellables: Set<AnyCancellable> = []

    init() {}

    func bind(modelContext: ModelContext, dictionary: RedactionDictionary) {
        self.modelContext = modelContext
        self.dictionary = dictionary
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

        // Keep transcript visible until session actually starts.
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

        // Let recorder.$isRecording drive the phase to .transcribing (avoids skipping states)
        if transcriber.isTranscribing {
            phase = .transcribing
            transcriber.stop()
        } else {
            phase = .idle
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
        guard activeTurnID == nil else { return }
        guard !isHandlingFileURL else { return }

        let path = url.path
        guard lastHandledFilePath != path else { return }
        lastHandledFilePath = path

        guard let repo else { return }

        isHandlingFileURL = true
        defer { isHandlingFileURL = false }

        do {
            activeTurnID = try repo.createCaptureTurn(audioPath: path)
        } catch {
            setError(.couldntStartCapture, debug: "createCaptureTurn failed: \(error.localizedDescription)")
            activeTurnID = nil
        }
    }

    private func handleRecorderRecordingChanged(_ isRecording: Bool) {
        if isRecording {
            if phase != .recording { phase = .recording }
            return
        }

        // If recording stops, we should now be transcribing (unless we already finished)
        if phase == .finalising || phase == .recording {
            phase = .transcribing
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

            lastCompletedTurnID = id
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

            if message == "No transcript captured." {
                if recorder.lastDurationSeconds >= 0.5 {
                    lastCompletedTurnID = id
                }
            }
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

