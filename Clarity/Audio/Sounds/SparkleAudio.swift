import AVFoundation
import Foundation

enum SparkleAudio {
    private static var player: AVAudioPlayer?

    static func play() {
        guard let url = Bundle.main.url(forResource: "sparkle", withExtension: "mp3") else {
            return
        }

        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            #endif

            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            print("Failed to play sparkle.mp3: \(error)")
        }
    }
}
