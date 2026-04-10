import SwiftUI

struct CaptureButton: View {
    let phase: TurnCaptureCoordinator.Phase
    let isEnabled: Bool
    let level: Double
    var size: CGFloat = 132
    var micIconScale: CGFloat = 0.265
    var stopIconScale: CGFloat = 0.30
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                // Material base (static)
                Circle()
                    .fill(.thinMaterial)

                // Audio-level pulse rings while recording
                if phase == .recording {
                    let v = min(1.0, pow(max(0.0, level), 0.75) * 1.6)

                    let ringScaleBase: CGFloat = 1.04
                    let ringScaleGain: CGFloat = 0.55
                    let ringScale = ringScaleBase + (ringScaleGain * v)

                    let ghostInset: CGFloat = 0.06
                    let ghostOpacityBase: Double = 0.08
                    let ghostOpacityGain: Double = 0.28
                    let ghostLineWidth: CGFloat = 2.0

                    Circle()
                        .strokeBorder(Color.red.opacity(0.9), lineWidth: ghostLineWidth)
                        .scaleEffect(max(1.001, ringScale - ghostInset))
                        .opacity(ghostOpacityBase + (ghostOpacityGain * Double(v)))
                        .allowsHitTesting(false)
                        .animation(
                            reduceMotion ? nil : .easeOut(duration: 0.10),
                            value: v
                        )

                    Circle()
                        .strokeBorder(Color.red.opacity(0.9), lineWidth: 2.6)
                        .scaleEffect(ringScale)
                        .opacity(0.12 + (0.45 * v))
                        .allowsHitTesting(false)
                        .animation(
                            reduceMotion ? nil : .easeOut(duration: 0.06),
                            value: v
                        )
                }

                // Icon swap (mic → stop)
                if phase == .recording {
                    Image(systemName: "stop.circle")
                        .font(.system(size: size * stopIconScale, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.red.opacity(0.95))
                } else {
                    Image(systemName: "mic")
                        .font(.system(size: size * micIconScale, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
        .tint(phase == .recording ? .red : .primary)

        // Accessibility
        .accessibilityLabel(
            String(localized: phase == .recording
                ? "capture.a11y.stop"
                : "capture.a11y.start")
        )
        .accessibilityHint(
            String(localized: phase == .recording
                ? "capture.a11y.hint.stop"
                : "capture.a11y.hint.start")
        )
        .accessibilityAddTraits(.isButton)
    }
}
