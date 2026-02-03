import Foundation
import AVFoundation
import Combine

@MainActor
final class LocalAudioPlayer: ObservableObject {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var lastError: String? = nil

    private var player: AVAudioPlayer?
    private var tickTask: Task<Void, Never>?

    func load(url: URL) {
        stop()

        // Guard: file must exist and be non-empty
        let path = url.path
        guard FileManager.default.fileExists(atPath: path) else {
            setPlaybackError("Audio file not found.")
            return
        }

        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: path)
            if let size = attrs[.size] as? NSNumber, size.int64Value <= 0 {
                setPlaybackError("Audio file is empty.")
                return
            }
        } catch {
            // If we can't read attrs, continue and let AVAudioPlayer validate.
        }

        do {
#if os(iOS)
            // Playback session for local audio
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
#endif
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()

            player = p
            duration = max(0, p.duration)
            currentTime = max(0, p.currentTime)
            lastError = nil
        } catch {
            player = nil
            duration = 0
            currentTime = 0

            let ns = error as NSError
            // Show something useful but not noisy.
            // 2003334207 often appears when the file can't be opened/decoded.
            if ns.code == 2003334207 {
                lastError = "Playback error: couldn't open audio."
            } else {
                lastError = "Playback error: \(ns.localizedDescription)"
            }
        }
    }

    func toggle() { isPlaying ? pause() : play() }

    func play() {
        guard lastError == nil else { return }
        guard let player else { return }
        guard player.duration > 0 else {
            setPlaybackError("Audio unavailable.")
            return
        }
        guard player.play() else {
            setPlaybackError("Playback failed.")
            return
        }

        isPlaying = true
        startTicking()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTicking()
        syncTime()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        duration = 0
        currentTime = 0
        lastError = nil
        stopTicking()
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        let t = max(0, min(time, player.duration))
        player.currentTime = t
        currentTime = t
    }

    private func startTicking() {
        stopTicking()
        tickTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                await MainActor.run {
                    guard let p = self.player else { return }

                    self.currentTime = p.currentTime
                    self.duration = p.duration

                    if !p.isPlaying {
                        self.isPlaying = false
                        self.stopTicking()
                    }
                }
            }
        }
    }

    private func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func syncTime() {
        guard let p = player else { return }
        currentTime = p.currentTime
        duration = p.duration
    }

    private func setPlaybackError(_ message: String) {
        player?.stop()
        player = nil
        isPlaying = false
        duration = 0
        currentTime = 0
        lastError = message
        stopTicking()
    }
}

