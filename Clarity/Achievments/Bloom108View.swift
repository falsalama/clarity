import SwiftUI

/// Renders a simple 108-petal ring around a minimal "moon seat".
///
/// Intentionally symbolic and restrained.
struct Bloom108View: View {
    let openCount: Int

    private let petalCount = 108

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let innerRadius = size * 0.30
            let outerRadius = size * 0.44
            let petalLength = outerRadius - innerRadius
            let petalWidth = size * 0.035

            ZStack {
                // Petals
                ForEach(0..<petalCount, id: \.self) { i in
                    let angle = (Double(i) / Double(petalCount)) * 2.0 * Double.pi
                    let isOpen = i < min(max(openCount, 0), petalCount)

                    PetalShape()
                        .fill(.primary.opacity(isOpen ? 0.16 : 0.04))
                        .overlay(
                            PetalShape()
                                .stroke(.primary.opacity(isOpen ? 0.20 : 0.08), lineWidth: 1)
                        )
                        .frame(width: petalWidth, height: petalLength)
                        .offset(y: -innerRadius - petalLength / 2)
                        .rotationEffect(.radians(angle))
                        .scaleEffect(isOpen ? 1.0 : 0.92)
                }

                // Moon seat (very simple: a soft disc + a small base)
                VStack(spacing: 8) {
                    Circle()
                        .fill(.primary.opacity(0.06))
                        .overlay(Circle().stroke(.primary.opacity(0.10), lineWidth: 1))
                        .frame(width: size * 0.26, height: size * 0.26)

                    RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                        .fill(.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                                .stroke(.primary.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: size * 0.36, height: size * 0.10)
                }
                .offset(y: size * 0.05)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.vertical, 12)
    }
}

private struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()

        let h = rect.height
        let midX = rect.midX

        // A simple pointed teardrop.
        p.move(to: CGPoint(x: midX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.55),
            control: CGPoint(x: rect.maxX, y: rect.minY + h * 0.15)
        )
        p.addQuadCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.55),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        p.addQuadCurve(
            to: CGPoint(x: midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + h * 0.15)
        )

        return p
    }
}
