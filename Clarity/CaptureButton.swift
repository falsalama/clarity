import SwiftUI

struct CaptureButton: View {
    let phase: TurnCaptureCoordinator.Phase
    let isEnabled: Bool
    let level: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Material base (static)
                Circle()
                    .fill(.thinMaterial)

                // Audio-level “pulse ring” while recording
                if phase == .recording {
                    let v = min(1.0, pow(max(0.0, level), 0.75) * 1.6)

                    // Main ring params
                    let ringScaleBase: CGFloat = 1.04
                    let ringScaleGain: CGFloat = 0.55
                    let ringScale = ringScaleBase + (ringScaleGain * v)

                    // Ghost trail params
                    let ghostInset: CGFloat = 0.06         // how much smaller than main ring (keeps it inside)
                    let ghostOpacityBase: Double = 0.08     // resting visibility
                    let ghostOpacityGain: Double = 0.28     // grows with level
                    let ghostLineWidth: CGFloat = 2.0       // thinner than main ring
                    let ghostAnim = Animation.easeOut(duration: 0.10)

                    // 1) Ghost trail ring
                    Circle()
                        .strokeBorder(Color.red.opacity(0.9), lineWidth: ghostLineWidth)
                        .scaleEffect(max(1.001, ringScale - ghostInset))
                        .opacity(ghostOpacityBase + (ghostOpacityGain * Double(v)))
                        .allowsHitTesting(false)
                        .animation(ghostAnim, value: v)

                    // 2) Main ring
                    Circle()
                        .strokeBorder(Color.red.opacity(0.9), lineWidth: 2.6)
                        .scaleEffect(ringScale)
                        .opacity(0.12 + (0.45 * v))
                        .allowsHitTesting(false)
                        .animation(.easeOut(duration: 0.06), value: v)
                }

                // Icon swap (mic → stop) while recording
                if phase == .recording {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.red.opacity(0.95))
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 132, height: 132)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.55)
        .tint(phase == .recording ? .red : .primary)
        .accessibilityLabel(String(localized: phase == .recording ? "capture.a11y.stop" : "capture.a11y.start"))
    }
}

