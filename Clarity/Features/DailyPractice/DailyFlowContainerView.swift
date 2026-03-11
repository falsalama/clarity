import SwiftUI
import AVFoundation

enum DailyFlowStep: Hashable {
    case reflect
    case focus
    case practice
}

private enum DailyFlowCompletionAudio {
    static var player: AVAudioPlayer?
}

struct DailyFlowContainerView: View {
    let startAt: DailyFlowStep
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var flow: AppFlowRouter
    
    @State private var currentStep: DailyFlowStep
    @State private var sparklePlayer: AVAudioPlayer?
    @State private var hasPlayedCompletionSound = false
    
    init(startAt: DailyFlowStep) {
        self.startAt = startAt
        _currentStep = State(initialValue: startAt)
    }
    
    var body: some View {
        Group {
            switch currentStep {
            case .reflect:
                CaptureView(
                    autoPopOnDone: false,
                    hideDailyQuestion: false,
                    embedInNavigationStack: false,
                    onDailyDone: {
                        currentStep = .focus
                    }
                )
                
            case .focus:
                FocusView(
                    onDailyDone: {
                        currentStep = .practice
                    }
                )
                
            case .practice:
                PracticeView()
            }
        }
        .onChange(of: flow.pendingOpenProgress) { _, shouldOpen in
            if shouldOpen {
                playCompletionSparkleThenDismiss()
            }
        }
    }
    private func playCompletionSparkleThenDismiss() {
        guard !hasPlayedCompletionSound else {
            dismiss()
            return
        }
        
        if let url = Bundle.main.url(forResource: "sparkle", withExtension: "mp3") {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                
                DailyFlowCompletionAudio.player = player
                hasPlayedCompletionSound = true
                
                let dismissDelay = max(0.2, min(0.45, player.duration * 0.35))
                DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                    dismiss()
                }
                return
            } catch {
                print("Failed to play sparkle.mp3: \(error)")
            }
        }
        
        dismiss()
    }
}
