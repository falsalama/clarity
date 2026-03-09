import SwiftUI
import AVFoundation

enum DailyFlowStep: Hashable {
    case reflect
    case focus
    case practice
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
                playCompletionSparkle()
                dismiss()
            }
        }
    }
            private func playCompletionSparkle() {
                guard !hasPlayedCompletionSound else { return }
                
                if let url = Bundle.main.url(forResource: "sparkle", withExtension: "mp3") {
                    do {
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                        try session.setActive(true)
                        
                        sparklePlayer = try AVAudioPlayer(contentsOf: url)
                        sparklePlayer?.prepareToPlay()
                        sparklePlayer?.play()
                        hasPlayedCompletionSound = true
                    } catch {
                        print("Failed to play sparkle.mp3: \(error)")
                    }
        }
    }
}
