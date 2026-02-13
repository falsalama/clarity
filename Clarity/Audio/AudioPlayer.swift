// AudioPlayer.swift

import Foundation
import AVFoundation
import Combine
#if os(iOS)
import MediaPlayer
#endif

/// Local file playback with CarPlay-compatible Now Playing + remote controls.
/// Swift 6–clean: no global @MainActor isolation; hops to MainActor only for UI state.
final class LocalAudioPlayer: ObservableObject {

    // MARK: - Published (UI-facing)

    @MainActor @Published private(set) var isPlaying: Bool = false
    @MainActor @Published private(set) var duration: TimeInterval = 0
    @MainActor @Published private(set) var currentTime: TimeInterval = 0
    @MainActor @Published private(set) var lastError: String? = nil

    // MARK: - Core

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    private var title: String = "Capture"

#if os(iOS)
    private var remoteInstalled = false
#endif

    deinit { teardown() }

    // MARK: - Public

    func load(storedAudioPath: String?) {
        stop()

        guard let url = FileStore.existingAudioURL(from: storedAudioPath),
              FileManager.default.fileExists(atPath: url.path)
        else {
            setError("Audio file not found.")
            return
        }

        title = normalizedTitle(from: url)

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

#if os(iOS)
        configureAudioSession()
        installRemoteCommandsIfNeeded()
#endif

        attachTimeObserver()
        attachEndObserver(item)

        Task { await refreshDuration() }
        updateNowPlaying()
    }

    func play() {
        guard let player else { return }
        player.play()
        setPlaying(true)
    }

    func pause() {
        guard let player else { return }
        player.pause()
        setPlaying(false)
    }

    func toggle() {
        if player?.timeControlStatus == .playing { pause() } else { play() }
    }

    func seek(to seconds: TimeInterval) {
        guard let player else { return }
        let clamped = max(0, seconds)
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero)
        Task { @MainActor in currentTime = clamped }
        updateNowPlaying(elapsed: clamped)
    }

    func stop() {
        teardown()
#if os(iOS)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
#endif
        Task { @MainActor in
            isPlaying = false
            duration = 0
            currentTime = 0
            lastError = nil
        }
    }

    // MARK: - Observers

    private func attachTimeObserver() {
        guard let player, timeObserver == nil else { return }

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = max(0, time.seconds.isFinite ? time.seconds : 0)
            Task { @MainActor in self.currentTime = seconds }
            self.updateNowPlaying(elapsed: seconds)
        }
    }

    private func attachEndObserver(_ item: AVPlayerItem) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.setPlaying(false)
        }
    }

    private func teardown() {
        if let token = timeObserver, let player {
            player.removeTimeObserver(token)
        }
        timeObserver = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil

        player?.pause()
        player = nil
    }

    // MARK: - State helpers

    private func setPlaying(_ playing: Bool) {
        Task { @MainActor in self.isPlaying = playing }
        updateNowPlaying()
    }

    private func setError(_ message: String) {
        Task { @MainActor in
            lastError = message
            isPlaying = false
        }
    }

    private func refreshDuration() async {
        guard let item = player?.currentItem else { return }
        do {
            let d = try await item.asset.load(.duration)
            let seconds = max(0, d.seconds.isFinite ? d.seconds : 0)
            await MainActor.run { duration = seconds }
            updateNowPlaying()
        } catch {
            // non-fatal
        }
    }

    private func normalizedTitle(from url: URL) -> String {
        let raw = url.deletingPathExtension().lastPathComponent
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Capture" : t
    }

    // MARK: - CarPlay / system integration

#if os(iOS)

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        // Playback + explicit output routing allowances (CarPlay/Bluetooth/AirPlay output).
        // (Options are documented by Apple; allowAirPlay is explicit, Bluetooth options are category options too.) :contentReference[oaicite:1]{index=1}
        let options: AVAudioSession.CategoryOptions = [
            .allowAirPlay,
            .allowBluetoothA2DP
        ]
        try? session.setCategory(.playback, mode: .default, options: options)
        try? session.setActive(true, options: [])
    }

    private func installRemoteCommandsIfNeeded() {
        guard !remoteInstalled else { return }
        remoteInstalled = true

        let cc = MPRemoteCommandCenter.shared()

        // Prevent duplicate handlers if this object is recreated.
        cc.playCommand.removeTarget(nil)
        cc.pauseCommand.removeTarget(nil)
        cc.togglePlayPauseCommand.removeTarget(nil)
        cc.changePlaybackPositionCommand.removeTarget(nil)

        cc.playCommand.isEnabled = true
        cc.pauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.isEnabled = true
        cc.changePlaybackPositionCommand.isEnabled = true

        cc.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        cc.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.toggle()
            return .success
        }

        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: e.positionTime)
            return .success
        }
    }

    private func updateNowPlaying(elapsed: TimeInterval? = nil) {
        let elapsedTime = elapsed ?? (player?.currentTime().seconds ?? 0)
        let playbackRate: Double = (player?.timeControlStatus == .playing) ? 1.0 : 0.0
        let dur = player?.currentItem?.duration.seconds ?? 0

        let info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, elapsedTime),
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPMediaItemPropertyPlaybackDuration: max(0, dur.isFinite ? dur : 0)
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

#endif
}
