import SwiftUI

struct SharedCaptureSurfaceView: View {
    @EnvironmentObject private var coordinator: TurnCaptureCoordinator

    let showPromptChips: Bool
    let showTypeButton: Bool

    var onTypeTap: () -> Void = {}

    private enum Layout {
        static let sectionCorner: CGFloat = 16

        static let statusPillSpacing: CGFloat = 8
        static let statusPillHPadding: CGFloat = 12
        static let statusPillVPadding: CGFloat = 8
        static let statusAnimDuration: Double = 0.15

        static let chipsTopPadding: CGFloat = 6
        static let chipsSpacing: CGFloat = 8
        static let chipHPadding: CGFloat = 12
        static let chipVPadding: CGFloat = 8
    }

    var body: some View {
        VStack(spacing: 12) {
            if showPromptChips {
                promptChips
            }

            micButton

            statusPill
                .animation(.easeInOut(duration: Layout.statusAnimDuration), value: coordinator.phase)

            if showTypeButton {
                typeTextButton
            }

            if let uiErrorKey = userFacingErrorKey {
                Text(LocalizedStringKey(uiErrorKey))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, -4)
            }
        }
    }

    // MARK: - Prompt chips

    private var promptChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.chipsSpacing) {
                chip("I already practice, but…")
                chip("I’m new but do know shamata…")
            }
            .padding(.top, Layout.chipsTopPadding)
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, Layout.chipHPadding)
            .padding(.vertical, Layout.chipVPadding)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .onTapGesture { onTypeTap() }
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Mic button

    private var micButton: some View {
        CaptureButton(
            phase: coordinator.phase,
            isEnabled: micButtonEnabled,
            level: coordinator.level
        ) {
            switch coordinator.phase {
            case .idle:
                coordinator.startCapture()
            case .recording:
                coordinator.stopCapture()
            default:
                break
            }
        }
        .padding(.top, 4)
    }

    private var micButtonEnabled: Bool {
        coordinator.phase == .idle || coordinator.phase == .recording
    }

    // MARK: - Status

    private var statusPill: some View {
        HStack(spacing: Layout.statusPillSpacing) {
            Text(LocalizedStringKey(statusTextKey))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if coordinator.phase == .recording {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(.secondary)
                    .opacity(0.85)
            }
        }
        .padding(.horizontal, Layout.statusPillHPadding)
        .padding(.vertical, Layout.statusPillVPadding)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }

    private var statusTextKey: String {
        switch coordinator.phase {
        case .idle: return "capture.ready"
        case .preparing: return "capture.preparing"
        case .recording: return "capture.listening"
        case .finalising, .transcribing, .redacting: return "capture.processing"
        }
    }

    // MARK: - Type button

    private var typeTextButton: some View {
        Button {
            onTypeTap()
        } label: {
            Text("Type text")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .disabled(coordinator.phase != .idle)
        .accessibilityLabel(Text("Type text"))
    }

    // MARK: - Errors

    private var userFacingErrorKey: String? {
        guard let err = coordinator.uiError else { return nil }

        switch err {
        case .notReady:
            return "error.capture.not_ready"
        case .couldntStartCapture:
            return "error.capture.start_failed"
        case .couldntSaveTranscript:
            return "error.capture.save_failed"
        case .noTranscriptCaptured:
            return "error.capture.no_speech"
        default:
            return nil
        }
    }
}
