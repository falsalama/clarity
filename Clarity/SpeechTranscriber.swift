// SpeechTranscriber.swift
import Foundation
import Speech
import Combine

@MainActor
final class SpeechTranscriber: ObservableObject {
    static let buildMarker = "ST_BUILD_MARKER__2026_01_26__E_LIVE_LONG__SAFE_ROTATE"

    @Published private(set) var isTranscribing: Bool = false
    @Published private(set) var liveTranscript: String = ""
    @Published private(set) var lastTranscript: String? = nil
    @Published private(set) var lastError: String? = nil

    private var recognizer: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var bufferCancellable: AnyCancellable?

    private var accumulatedText: String = ""
    private var segmentLatestText: String = ""
    private var segmentStartTime: Date = Date()

    private var segmentTimer: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    private let segmentSeconds: Int = 8
    private let defaultTimeoutSeconds: Int = 60 * 60

    private var awaitingFinalContinuation: CheckedContinuation<Void, Never>?

    // MARK: - UI-only reset (safe)

    func resetUI() {
        lastError = nil
        lastTranscript = nil
        liveTranscript = ""
    }

    // MARK: - Session lifecycle

    /// Starts the speech session (auth + recogniser + request/task). Does NOT attach audio buffers.
    /// Call `attach(to:)` before audio starts flowing.
    func startSession(timeoutSeconds: Int? = nil) async -> Bool {
        stopInternal(resetPublished: false)

        lastError = nil
        lastTranscript = nil
        // Do not clear liveTranscript here; caller decides when to clear UI.

        accumulatedText = ""
        segmentLatestText = ""
        segmentStartTime = Date()

        guard await ensureSpeechAuth() else {
            finish(error: "Speech not authorised.")
            return false
        }

        let rec = SFSpeechRecognizer(locale: Locale(identifier: "en_GB"))
        recognizer = rec

        guard let rec, rec.isAvailable else {
            finish(error: "Speech recogniser unavailable.")
            return false
        }

        startNewSegment(recognizer: rec)
        startSegmentTimer()
        startTimeout(seconds: timeoutSeconds ?? defaultTimeoutSeconds)

        isTranscribing = true
        return true
    }

    /// Attaches recorder buffers to the current request. Safe to call only after `startSession() == true`.
    func attach(to recorder: AudioRecorder) {
        bufferCancellable?.cancel()
        bufferCancellable = recorder.bufferPublisher
            .sink { [weak self] buffer in
                Task { @MainActor in
                    self?.request?.append(buffer)
                }
            }
    }

    func stop() {
        guard isTranscribing else { return }

        Task { @MainActor in
            segmentTimer?.cancel(); segmentTimer = nil
            timeoutTask?.cancel(); timeoutTask = nil

            bufferCancellable?.cancel()
            bufferCancellable = nil

            await flushCurrentSegment(waitSeconds: 0.9)

            let combined = joinTranscript(accumulatedText, segmentLatestText)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if combined.isEmpty {
                finish(error: "No transcript captured.")
            } else {
                lastTranscript = combined
                liveTranscript = combined
                finish(text: combined)
            }
        }
    }

    func cancel() {
        guard isTranscribing else { return }
        stopInternal(resetPublished: false)
        finish(error: "Transcription cancelled.")
    }

    // MARK: - Segments

    private func startNewSegment(recognizer: SFSpeechRecognizer) {
        let oldTask = task
        let oldRequest = request

        segmentLatestText = ""
        segmentStartTime = Date()

        let newReq = SFSpeechAudioBufferRecognitionRequest()
        newReq.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            newReq.requiresOnDeviceRecognition = true
        }

        request = newReq

        task = recognizer.recognitionTask(with: newReq) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.commitCurrentSegmentBestEffort()
                    self.updateLiveTranscript()
                    self.signalAwaitingFinal()

                    if self.accumulatedText.isEmpty && self.segmentLatestText.isEmpty {
                        self.finish(error: "Transcription error: \(error.localizedDescription)")
                    }
                    return
                }

                guard let result else { return }

                self.segmentLatestText = result.bestTranscription.formattedString
                self.updateLiveTranscript()

                if result.isFinal {
                    self.commitCurrentSegmentBestEffort()
                    self.updateLiveTranscript()
                    self.signalAwaitingFinal()
                }
            }
        }

        oldRequest?.endAudio()
        oldTask?.cancel()
    }

    private func startSegmentTimer() {
        segmentTimer?.cancel()
        segmentTimer = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                await MainActor.run {
                    guard self.isTranscribing else { return }
                    let elapsed = Date().timeIntervalSince(self.segmentStartTime)
                    if elapsed >= Double(self.segmentSeconds) {
                        self.rotateSegment()
                    }
                }
            }
        }
    }

    private func rotateSegment() {
        guard isTranscribing, let rec = recognizer else { return }
        Task { @MainActor in
            await flushCurrentSegment(waitSeconds: 0.6)
            self.startNewSegment(recognizer: rec)
        }
    }

    private func flushCurrentSegment(waitSeconds: Double) async {
        request?.endAudio()

        await withCheckedContinuation { cont in
            awaitingFinalContinuation = cont
            Task { [weak self] in
                guard let self else { return }
                let nanos = UInt64(max(0.1, waitSeconds) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                await MainActor.run {
                    self.commitCurrentSegmentBestEffort()
                    self.updateLiveTranscript()
                    self.signalAwaitingFinal()
                }
            }
        }
    }

    private func commitCurrentSegmentBestEffort() {
        let text = segmentLatestText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            accumulatedText = joinTranscript(accumulatedText, text)
        }
        segmentLatestText = ""
    }

    private func updateLiveTranscript() {
        liveTranscript = joinTranscript(accumulatedText, segmentLatestText)
    }

    private func signalAwaitingFinal() {
        awaitingFinalContinuation?.resume()
        awaitingFinalContinuation = nil
    }

    // MARK: - Timeout

    private func startTimeout(seconds: Int) {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            let nanos = UInt64(max(1, seconds)) * 1_000_000_000
            try? await Task.sleep(nanoseconds: nanos)
            await MainActor.run {
                guard self.isTranscribing else { return }
                self.stop()
            }
        }
    }

    // MARK: - Stop internal / Finish

    private func stopInternal(resetPublished: Bool) {
        timeoutTask?.cancel(); timeoutTask = nil
        segmentTimer?.cancel(); segmentTimer = nil

        bufferCancellable?.cancel()
        bufferCancellable = nil

        request?.endAudio()
        request = nil

        task?.cancel()
        task = nil

        recognizer = nil

        awaitingFinalContinuation?.resume()
        awaitingFinalContinuation = nil

        if resetPublished {
            lastError = nil
            lastTranscript = nil
            liveTranscript = ""
        }

        isTranscribing = false
    }

    private func finish(text: String) {
        lastError = nil
        isTranscribing = false
    }

    private func finish(error message: String) {
        lastError = message
        isTranscribing = false
    }

    // MARK: - Auth

    private func ensureSpeechAuth() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized { return true }
        if status == .denied || status == .restricted { return false }

        return await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { newStatus in
                cont.resume(returning: newStatus == .authorized)
            }
        }
    }

    // MARK: - Join

    private func joinTranscript(_ a: String, _ b: String) -> String {
        let left = a.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = b.trimmingCharacters(in: .whitespacesAndNewlines)
        if left.isEmpty { return right }
        if right.isEmpty { return left }
        return left + " " + right
    }
}

