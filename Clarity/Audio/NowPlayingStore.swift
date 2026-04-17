import Foundation
import AVFoundation
import Combine
import SwiftUI
#if os(iOS)
import MediaPlayer
import UIKit
#endif

struct AudioTrack: Identifiable {
    let title: String
    let subtitle: String
    let note: String
    let fileName: String
    let artworkAssetName: String?
    let durationLabel: String
    let tint: Color
    let collectionTitle: String?

    init(
        title: String,
        subtitle: String,
        note: String,
        fileName: String,
        artworkAssetName: String?,
        durationLabel: String,
        tint: Color,
        collectionTitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.note = note
        self.fileName = fileName
        self.artworkAssetName = artworkAssetName
        self.durationLabel = durationLabel
        self.tint = tint
        self.collectionTitle = collectionTitle
    }

    var id: String { fileName }
}

typealias TeachingAudioTrack = AudioTrack

enum TeachingsLibrary {
    static let tracks: [AudioTrack] = [
        .init(
            title: "Nun Monlam",
            subtitle: "Prayer and contemplative recitation",
            note: "A simple listening card layout for teachings, chants, and spoken audio.",
            fileName: "focus-nun-monlam",
            artworkAssetName: "placeholder1",
            durationLabel: "1m 45s",
            tint: Color(red: 0.46, green: 0.12, blue: 0.14)
        ),
        .init(
            title: "Nothing To Hold",
            subtitle: "A spacious reflective song",
            note: "Swipe between items above, or choose one below to play it directly.",
            fileName: "Nothing To Hold",
            artworkAssetName: "placeholder2",
            durationLabel: "3m 04s",
            tint: Color(red: 0.69, green: 0.54, blue: 0.17)
        ),
        .init(
            title: "Pristine Space",
            subtitle: "Clear contemplative atmosphere",
            note: "This can later point at dedicated teaching recordings without changing the page layout.",
            fileName: "pristine-space",
            artworkAssetName: "placeholder3",
            durationLabel: "3m 27s",
            tint: Color(red: 0.21, green: 0.34, blue: 0.66)
        )
    ]
}

final class NowPlayingStore: NSObject, ObservableObject, AVAudioPlayerDelegate {
    enum MiniPlayerStyle {
        case full
        case compact
    }

    static let shared = NowPlayingStore()

    @MainActor @Published private(set) var currentItem: AudioTrack?
    @MainActor @Published private(set) var isPlaying = false
    @MainActor @Published private(set) var currentTime: TimeInterval = 0
    @MainActor @Published private(set) var duration: TimeInterval = 0
    @MainActor @Published var isExpanded = false
    @MainActor @Published private(set) var miniPlayerStyle: MiniPlayerStyle = .full

    private var queue: [AudioTrack] = []
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
#if os(iOS)
    private var remoteInstalled = false
#endif

    private override init() {
        super.init()
    }

    @MainActor var showsMiniPlayer: Bool {
        currentItem != nil && miniPlayerStyle == .full
    }

    @MainActor var showsCompactPlayer: Bool {
        currentItem != nil && miniPlayerStyle == .compact
    }

    @MainActor var chromeStateToken: String {
        if currentItem == nil { return "hidden" }
        return miniPlayerStyle == .full ? "full" : "compact"
    }

    @MainActor var canPlayPrevious: Bool {
        guard let currentItem,
              let currentIndex = queue.firstIndex(where: { $0.id == currentItem.id }) else {
            return false
        }
        return currentIndex > 0 || currentTime > 0
    }

    @MainActor var canPlayNext: Bool {
        guard let currentItem,
              let currentIndex = queue.firstIndex(where: { $0.id == currentItem.id }) else {
            return false
        }
        return currentIndex < queue.count - 1
    }

    @MainActor
    func setQueue(_ items: [AudioTrack]) {
        queue = items
    }

    @MainActor
    func play(_ item: AudioTrack, queue items: [AudioTrack]? = nil) {
        if let items {
            queue = items
        }

        if currentItem?.id == item.id, audioPlayer != nil {
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }

        miniPlayerStyle = .full
        load(item, autoplay: true)
    }

    @MainActor
    func resume() {
        guard let audioPlayer else { return }
        audioPlayer.play()
        isPlaying = true
        startTimer()
        updateNowPlaying()
        updateRemoteCommandAvailability()
    }

    @MainActor
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
        updateNowPlaying()
        updateRemoteCommandAvailability()
    }

    @MainActor
    func toggleCurrent() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    @MainActor
    func seek(to seconds: TimeInterval) {
        guard let audioPlayer else { return }
        let clamped = min(max(seconds, 0), audioPlayer.duration)
        audioPlayer.currentTime = clamped
        currentTime = clamped
        updateNowPlaying(elapsed: clamped)
        updateRemoteCommandAvailability()
    }

    @MainActor
    func playNext() {
        guard let currentItem, let currentIndex = queue.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let nextIndex = min(currentIndex + 1, queue.count - 1)
        guard nextIndex != currentIndex else { return }
        load(queue[nextIndex], autoplay: true)
    }

    @MainActor
    func playPrevious() {
        guard let currentItem, let currentIndex = queue.firstIndex(where: { $0.id == currentItem.id }) else { return }

        if currentTime > 3 {
            seek(to: 0)
            resume()
            return
        }

        let previousIndex = max(currentIndex - 1, 0)
        guard previousIndex != currentIndex else {
            seek(to: 0)
            return
        }
        load(queue[previousIndex], autoplay: true)
    }

    @MainActor
    func stop() {
        stopTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        currentItem = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        miniPlayerStyle = .full
        clearNowPlaying()
        updateRemoteCommandAvailability()
    }

    @MainActor
    func collapse() {
        isExpanded = false
    }

    @MainActor
    func expand() {
        guard currentItem != nil else { return }
        isExpanded = true
    }

    @MainActor
    func restoreMiniPlayer() {
        guard currentItem != nil else { return }
        miniPlayerStyle = .full
    }

    @MainActor
    func minimizeMiniPlayer() {
        guard currentItem != nil else { return }
        miniPlayerStyle = .compact
    }

    @MainActor
    private func load(_ item: AudioTrack, autoplay: Bool) {
        stopTimer()
        audioPlayer?.stop()

        let supportedExtensions = ["m4a", "mp3"]
        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: item.fileName, withExtension: $0) }).first else {
            currentItem = nil
            audioPlayer = nil
            isPlaying = false
            currentTime = 0
            duration = 0
            return
        }

        do {
            #if os(iOS)
            configureAudioSession()
            installRemoteCommandsIfNeeded()
            #endif

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()

            currentItem = item
            audioPlayer = player
            currentTime = 0
            duration = player.duration
            isPlaying = false
            updateNowPlaying(elapsed: 0)
            updateRemoteCommandAvailability()

            if autoplay {
                resume()
            }
        } catch {
            currentItem = nil
            audioPlayer = nil
            isPlaying = false
            currentTime = 0
            duration = 0
            clearNowPlaying()
            updateRemoteCommandAvailability()
        }
    }

    @MainActor
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(handleTimerTick), userInfo: nil, repeats: true)
    }

    @MainActor
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc @MainActor
    private func handleTimerTick() {
        guard let audioPlayer else { return }
        currentTime = audioPlayer.currentTime
        duration = audioPlayer.duration
        updateNowPlaying(elapsed: currentTime)
        updateRemoteCommandAvailability()
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopTimer()

            guard let currentItem,
                  let currentIndex = self.queue.firstIndex(where: { $0.id == currentItem.id }) else {
                self.isPlaying = false
                self.currentTime = player.duration
                return
            }

            let nextIndex = currentIndex + 1
            if nextIndex < self.queue.count {
                self.load(self.queue[nextIndex], autoplay: true)
            } else {
                self.isPlaying = false
                self.currentTime = player.duration
                self.updateNowPlaying(elapsed: player.duration)
                self.updateRemoteCommandAvailability()
            }
        }
    }

#if os(iOS)
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
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

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggleCurrent() }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            Task { @MainActor in self?.seek(to: event.positionTime) }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playNext() }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playPrevious() }
            return .success
        }
    }

    @MainActor
    private func updateRemoteCommandAvailability() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = canPlayNext
        commandCenter.previousTrackCommand.isEnabled = canPlayPrevious
    }

    @MainActor
    private func updateNowPlaying(elapsed: TimeInterval? = nil) {
        guard let currentItem else {
            clearNowPlaying()
            return
        }

        let elapsedTime = elapsed ?? currentTime
        let playbackRate: Double = isPlaying ? 1.0 : 0.0
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentItem.title,
            MPMediaItemPropertyArtist: currentItem.subtitle,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, elapsedTime),
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPMediaItemPropertyPlaybackDuration: max(0, duration)
        ]

        if let assetName = currentItem.artworkAssetName,
           let image = UIImage(named: assetName) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
#else
    @MainActor private func updateRemoteCommandAvailability() {}
    @MainActor private func updateNowPlaying(elapsed: TimeInterval? = nil) {}
    private func clearNowPlaying() {}
#endif
}
