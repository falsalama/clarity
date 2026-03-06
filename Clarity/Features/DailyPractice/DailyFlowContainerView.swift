import SwiftUI

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
                dismiss()
            }
        }
    }
}
