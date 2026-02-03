import Foundation
import Speech
import Combine

@MainActor
final class SpeechTranscriber: ObservableObject {
    static let buildMarker = "ST_BUILD_MARKER__2026_02_03__FLUSH_CONTINUATION_FIX_V3"

    @Published private(set) var isTranscribing: Bool = false
    @Published private(set) var liveTranscript: String = ""
    @Published private(set) var lastTranscript: String? = nil
    @Published private(set) var lastError: String? = nil

    private var recognizer: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var bufferCancellable: AnyCancellable?

    private var accumulatedText: String = ""

    // For the current recognition task only:
    private var segmentCommittedText: String = ""     // stable chunk (won’t rewrite / won’t shrink)
    private var segmentLiveTailText: String = ""      // tentative tail (allowed to rewrite)
    private var segmentStartTime: Date = Date()

    private var segmentTimer: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    private let segmentSeconds: Int = 30
    private let defaultTimeoutSeconds: Int = 60 * 60

    // How far behind "now" we treat words as stable.
    private let stabilityLagSeconds: TimeInterval = 1.1

    private var awaitingFinalContinuation: CheckedContinuation<Void, Never>?

    // Ignore late callbacks from cancelled tasks
    private var segmentToken: Int = 0

    // Guards against recogniser “rewind/reset”
    private var lastFullBestText: String = ""

    // If a partial update shrinks a lot, treat as reset and ignore.
    private let catastrophicShrinkChars: Int = 40

    // Ensure a segment is finalised (committed) at most once per token
    private var finalisedToken: Int = -1

    // Flush continuation safety
    private var flushWaiterTask: Task<Void, Never>?
    private var flushToken: Int = 0
    private var isFlushing: Bool = false

    // MARK: - UI reset (published only)

    func resetUI() {
        lastError = nil
        lastTranscript = nil
        liveTranscript = ""
    }

    // MARK: - Hard reset (published + internal buffers + invalidate callbacks)

    func hardResetAll() {
        segmentToken &+= 1
        finalisedToken = -1

        flushWaiterTask?.cancel()
        flushWaiterTask = nil
        isFlushing = false

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

        accumulatedText = ""
        segmentCommittedText = ""
        segmentLiveTailText = ""
        lastFullBestText = ""
        segmentStartTime = Date()

        lastError = nil
        lastTranscript = nil
        liveTranscript = ""
        isTranscribing = false
    }

    // MARK: - Session lifecycle

    func startSession(timeoutSeconds: Int? = nil) async -> Bool {
        stopInternal(resetPublished: false)

        lastError = nil
        lastTranscript = nil

        accumulatedText = ""
        segmentCommittedText = ""
        segmentLiveTailText = ""
        segmentStartTime = Date()
        lastFullBestText = ""
        finalisedToken = -1

        flushWaiterTask?.cancel()
        flushWaiterTask = nil
        flushToken = 0
        isFlushing = false

        segmentToken &+= 1

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

            await flushCurrentSegment(waitSeconds: 1.0)

            let combined = joinTranscript(
                accumulatedText,
                joinTranscript(segmentCommittedText, segmentLiveTailText)
            )
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
        segmentToken &+= 1
        let myToken = segmentToken

        segmentCommittedText = ""
        segmentLiveTailText = ""
        segmentStartTime = Date()
        lastFullBestText = ""

        let oldTask = task
        let oldRequest = request

        let newReq = SFSpeechAudioBufferRecognitionRequest()
        newReq.shouldReportPartialResults = true
        newReq.taskHint = .dictation

        if recognizer.supportsOnDeviceRecognition {
            newReq.requiresOnDeviceRecognition = true
        }

        request = newReq

        task = recognizer.recognitionTask(with: newReq) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                guard myToken == self.segmentToken else { return }
                guard self.isTranscribing else { return }

                if let error {
                    self.finaliseSegmentOnce(token: myToken, finalize: true)
                    self.updateLiveTranscript()
                    self.signalAwaitingFinal()

                    if self.accumulatedText.isEmpty &&
                        self.segmentCommittedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        self.segmentLiveTailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.finish(error: "Transcription error: \(error.localizedDescription)")
                    }
                    return
                }

                guard let result else { return }

                let best = result.bestTranscription.formattedString
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if self.shouldIgnoreCatastrophicShrink(candidate: best) {
                    return
                }
                self.lastFullBestText = best

                self.updateFromSegments(result.bestTranscription.segments)

                if result.isFinal {
                    self.finaliseSegmentOnce(token: myToken, finalize: true)
                    self.updateLiveTranscript()
                    self.signalAwaitingFinal()
                }
            }
        }

        oldRequest?.endAudio()
        oldTask?.cancel()
    }

    private func updateFromSegments(_ segments: [SFTranscriptionSegment]) {
        guard !segments.isEmpty else { return }

        let last = segments[segments.count - 1]
        let nowEnd = last.timestamp + last.duration
        let stableCutoff = max(0, nowEnd - stabilityLagSeconds)

        var stableParts: [String] = []
        var tailParts: [String] = []

        for seg in segments {
            let end = seg.timestamp + seg.duration
            if end <= stableCutoff {
                stableParts.append(seg.substring)
            } else {
                tailParts.append(seg.substring)
            }
        }

        let candidateStable = stableParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let candidateTail = tailParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        if segmentCommittedText.isEmpty {
            segmentCommittedText = candidateStable
        } else if candidateStable.isEmpty {
            // never replace committed stable with empty
        } else if candidateStable.hasPrefix(segmentCommittedText) {
            segmentCommittedText = candidateStable
        } else if segmentCommittedText.hasPrefix(candidateStable) {
            // shrink attempt: ignore
        } else if candidateStable.count >= segmentCommittedText.count {
            segmentCommittedText = candidateStable
        } else {
            // different and shorter: ignore
        }

        if !candidateTail.isEmpty || segmentLiveTailText.isEmpty {
            segmentLiveTailText = candidateTail
        }

        updateLiveTranscript()
    }

    private func shouldIgnoreCatastrophicShrink(candidate: String) -> Bool {
        guard isTranscribing else { return false }

        let prev = lastFullBestText
        if prev.isEmpty { return false }
        if candidate.isEmpty { return true }

        if candidate.count + catastrophicShrinkChars < prev.count {
            return true
        }

        return false
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
        guard isTranscribing, recognizer != nil else { return }
        Task { @MainActor in
            await flushCurrentSegment(waitSeconds: 0.8)
            if let rec = self.recognizer {
                self.startNewSegment(recognizer: rec)
            }
        }
    }

    private func flushCurrentSegment(waitSeconds: Double) async {
        // Prevent re-entrant flushes from overwriting the continuation
        if isFlushing { return }
        isFlushing = true
        defer { isFlushing = false }

        request?.endAudio()

        // Kill any previous waiter and resume any previous continuation to avoid leaks.
        flushWaiterTask?.cancel()
        flushWaiterTask = nil

        if awaitingFinalContinuation != nil {
            awaitingFinalContinuation?.resume()
            awaitingFinalContinuation = nil
        }

        flushToken &+= 1
        let myFlush = flushToken

        await withTaskCancellationHandler {
            await withCheckedContinuation { cont in
                awaitingFinalContinuation = cont

                flushWaiterTask = Task { [weak self] in
                    guard let self else { return }
                    let nanos = UInt64(max(0.1, waitSeconds) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nanos)

                    await MainActor.run {
                        guard self.flushToken == myFlush else { return }

                        self.finaliseSegmentOnce(token: self.segmentToken, finalize: true)
                        self.updateLiveTranscript()
                        self.signalAwaitingFinal()
                    }
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                // This runs on MainActor; weak capture avoids retaining self.
                self?.signalAwaitingFinal()
            }
        }


        flushWaiterTask?.cancel()
        flushWaiterTask = nil
    }

    private func finaliseSegmentOnce(token: Int, finalize: Bool) {
        guard finalisedToken != token else { return }
        finalisedToken = token
        commitCurrentSegmentBestEffort(finalize: finalize)
    }

    private func commitCurrentSegmentBestEffort(finalize: Bool) {
        let stable = segmentCommittedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let tail = segmentLiveTailText.trimmingCharacters(in: .whitespacesAndNewlines)

        let toCommit: String = finalize ? joinTranscript(stable, tail) : stable

        if !toCommit.isEmpty {
            accumulatedText = joinTranscript(accumulatedText, toCommit)
        }

        segmentCommittedText = ""
        segmentLiveTailText = ""
        lastFullBestText = ""
    }

    private func updateLiveTranscript() {
        let current = joinTranscript(segmentCommittedText, segmentLiveTailText)
        let combined = joinTranscript(accumulatedText, current)

        if isTranscribing, combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        liveTranscript = combined
    }

    private func signalAwaitingFinal() {
        flushWaiterTask?.cancel()
        flushWaiterTask = nil

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

        flushWaiterTask?.cancel()
        flushWaiterTask = nil
        isFlushing = false

        bufferCancellable?.cancel()
        bufferCancellable = nil

        segmentToken &+= 1
        finalisedToken = -1

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
        if message == "No transcript captured." {
            let hasAnyText =
                (lastTranscript?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ||
                (liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ||
                (!accumulatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
                (!segmentCommittedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
                (!segmentLiveTailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if hasAnyText {
                isTranscribing = false
                return
            }
        }

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

