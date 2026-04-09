import Foundation
import AVFoundation
import Combine

final class FocusAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = FocusAudioPlayer()

    @Published var currentID: String?
    @Published var isCurrentlyPlaying = false

    private var audioPlayer: AVAudioPlayer?

    private override init() {
        super.init()
    }

    func toggle(id: String, fileName: String) {
        if currentID == id, let audioPlayer {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                isCurrentlyPlaying = false
            } else {
                audioPlayer.play()
                isCurrentlyPlaying = true
            }
            return
        }

        play(id: id, fileName: fileName)
    }

    func isPlaying(id: String) -> Bool {
        currentID == id && isCurrentlyPlaying
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentID = nil
        isCurrentlyPlaying = false
    }

    private func play(id: String, fileName: String) {
        let extensions = ["m4a", "mp3"]
        guard let url = extensions.compactMap({ Bundle.main.url(forResource: fileName, withExtension: $0) }).first else {
            print("FocusAudioPlayer: missing file \(fileName).m4a/.mp3")
            stop()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            currentID = id
            isCurrentlyPlaying = true
        } catch {
            print("FocusAudioPlayer: failed to play \(fileName) - \(error)")
            stop()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentID = nil
        isCurrentlyPlaying = false
        audioPlayer = nil
    }
}
