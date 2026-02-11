import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRecorder: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var lastFileURL: URL? = nil
    @Published var lastError: String? = nil

    /// 0.0 ... 1.0 (live mic level while recording). 0 when idle.
    @Published private(set) var level: Double = 0

    /// Duration of the *most recent* recording (seconds). Updated on stop.
    @Published private(set) var lastDurationSeconds: TimeInterval = 0

    /// Live audio buffers for streaming transcription (local-only).
    nonisolated let bufferPublisher = PassthroughSubject<AVAudioPCMBuffer, Never>()

    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var meterTask: Task<Void, Never>?

    private var recordingStartedAt: Date? = nil

    // Cancels late permission callbacks / late starts.
    private var startToken: UInt64 = 0

    // MARK: - Public

    func start() {
        // New intent to start; invalidate any prior pending permission callbacks.
        startToken &+= 1
        let token = startToken

        lastError = nil
        lastDurationSeconds = 0
        recordingStartedAt = nil

#if os(iOS)
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                startRecordingNow(ifTokenMatches: token)
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    guard let self else { return }
                    Task { @MainActor in
                        // Ignore late callbacks if a stop/new-start happened.
                        guard self.startToken == token else { return }
                        if granted { self.startRecordingNow(ifTokenMatches: token) }
                        else { self.lastError = "Microphone permission not granted." }
                    }
                }
            case .denied:
                lastError = "Microphone permission denied."
            @unknown default:
                lastError = "Microphone permission state unknown."
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                startRecordingNow(ifTokenMatches: token)
            case .undetermined:
                session.requestRecordPermission { [weak self] granted in
                    guard let self else { return }
                    Task { @MainActor in
                        guard self.startToken == token else { return }
                        if granted { self.startRecordingNow(ifTokenMatches: token) }
                        else { self.lastError = "Microphone permission not granted." }
                    }
                }
            case .denied:
                lastError = "Microphone permission denied."
            @unknown default:
                lastError = "Microphone permission state unknown."
            }
        }
#elseif os(macOS)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            startRecordingNow(ifTokenMatches: token)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                guard let self else { return }
                Task { @MainActor in
                    guard self.startToken == token else { return }
                    if granted { self.startRecordingNow(ifTokenMatches: token) }
                    else { self.lastError = "Microphone permission not granted." }
                }
            }
        case .denied, .restricted:
            lastError = "Microphone permission denied."
        @unknown default:
            lastError = "Microphone permission state unknown."
        }
#endif
    }

    func stop() {
        // Always invalidate any pending permission callbacks / late starts.
        startToken &+= 1

        stopMetering()

        // duration
        if let started = recordingStartedAt {
            lastDurationSeconds = Date().timeIntervalSince(started)
        } else {
            lastDurationSeconds = 0
        }
        recordingStartedAt = nil

        // Remove tap if present (safe to call even if no tap installed).
        engine.inputNode.removeTap(onBus: 0)

        if engine.isRunning {
            engine.stop()
            engine.reset()
        }

        audioFile = nil
        isRecording = false
        level = 0

#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }

    // MARK: - Internals

    private func startRecordingNow(ifTokenMatches token: UInt64) {
        // If stop() (or a new start) happened before we got here, ignore.
        guard startToken == token else { return }

        do {
#if os(iOS)
            let session = AVAudioSession.sharedInstance()
            // Speech-friendly capture. Avoids gating/chunking seen with .spokenAudio.
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
#endif
            let url = try makeNewRecordingURL(extension: "caf")
            lastFileURL = url

            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            // CAF writer (lossless PCM).
            let file = try AVAudioFile(
                forWriting: url,
                settings: format.settings,
                commonFormat: format.commonFormat,
                interleaved: format.isInterleaved
            )
            audioFile = file

            inputNode.removeTap(onBus: 0)

            // Keep the tap realtime-safe: no allocations/copies, no async hops.
            inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
                guard let self else { return }

                // Publish for speech recognition
                self.bufferPublisher.send(buffer)

                // Write directly
                do {
                    try self.audioFile?.write(from: buffer)
                } catch {
                    Task { @MainActor in
                        self.lastError = "Audio write error: \(error.localizedDescription)"
                    }
                }

                // Update level (cheap RMS)
                let lvl = Self.normalisedLevel(from: buffer)
                Task { @MainActor in
                    if self.isRecording { self.level = lvl }
                }
            }

            engine.prepare()
            try engine.start()

            // If stop() happened during engine.start(), don't “resurrect” recording.
            guard startToken == token else {
                stop() // cleans up engine/tap/session safely
                return
            }

            // Mark started only once engine is actually running
            isRecording = true
            recordingStartedAt = Date()
            lastDurationSeconds = 0

            startMeteringFallback()
        } catch {
            lastError = "Recording error: \(error.localizedDescription)"
            isRecording = false
            level = 0
            audioFile = nil
            recordingStartedAt = nil
            lastDurationSeconds = 0
        }
    }

    private func startMeteringFallback() {
        stopMetering()
        meterTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
                await MainActor.run {
                    if !self.isRecording { self.level = 0 }
                }
            }
        }
    }

    private func stopMetering() {
        meterTask?.cancel()
        meterTask = nil
    }

    private static func normalisedLevel(from buffer: AVAudioPCMBuffer) -> Double {
        let n = Int(buffer.frameLength)
        guard n > 0 else { return 0 }

        if let f = buffer.floatChannelData?[0] {
            var sum: Float = 0
            for i in 0..<n { sum += f[i] * f[i] }
            let rms = sqrt(sum / Float(n))
            return min(1.0, max(0.0, Double(rms) * 8.0))
        }

        if let i16 = buffer.int16ChannelData?[0] {
            var sum: Double = 0
            for i in 0..<n {
                let x = Double(i16[i]) / 32768.0
                sum += x * x
            }
            let rms = sqrt(sum / Double(n))
            return min(1.0, max(0.0, rms * 8.0))
        }

        return 0
    }

    private func makeNewRecordingURL(extension ext: String) throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let dir = base
            .appendingPathComponent("Clarity", isDirectory: true)
            .appendingPathComponent("audio", isDirectory: true)

        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "yyyyMMdd_HHmmss"

        let filename = "clarity_\(formatter.string(from: Date())).\(ext)"
        return dir.appendingPathComponent(filename)
    }
}

