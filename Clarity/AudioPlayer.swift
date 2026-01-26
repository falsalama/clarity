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

        do {
#if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
#endif
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()

            player = p
            duration = p.duration
            currentTime = p.currentTime
            lastError = nil
        } catch {
            player = nil
            duration = 0
            currentTime = 0
            lastError = "Playback error: \(error.localizedDescription)"
        }
    }

    func toggle() { isPlaying ? pause() : play() }

    func play() {
        guard let player else { return }
        guard player.play() else { return }

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
}

