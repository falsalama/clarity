import SwiftUI

struct DoneFeedback: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content
            .symbolEffect(.bounce, value: trigger)
            .sensoryFeedback(.success, trigger: trigger)
            .overlay {
                RippleRing(trigger: trigger)
            }
    }
}

extension View {
    func doneFeedback(trigger: Int) -> some View {
        modifier(DoneFeedback(trigger: trigger))
    }
}

private struct RippleRing: View {
    let trigger: Int
    @State private var t: CGFloat = 0

    var body: some View {
        Capsule()
            .strokeBorder(Color.primary.opacity(0.28), lineWidth: 2.5)
            .scaleEffect(1 + (0.9 * t))
            .opacity(trigger == 0 ? 0 : (1 - t))
            .blur(radius: 9 * t)
            .onChange(of: trigger) { _, _ in
                t = 0
                withAnimation(.easeOut(duration: 1.2)) {
                    t = 1
                }
            }
            .allowsHitTesting(false)
    }
}
