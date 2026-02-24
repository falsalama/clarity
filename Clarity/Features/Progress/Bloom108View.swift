import SwiftUI

struct Bloom108View: View {
    let openCount: Int
    let portraitRecipe: PortraitRecipe
    let onPortraitTap: () -> Void

    private let petalCount = 108

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let innerRadius = size * 0.30
            let outerRadius = size * 0.44
            let basePetalLength = outerRadius - innerRadius
            let basePetalWidth = size * 0.035

            ZStack {
                ForEach(0..<petalCount, id: \.self) { i in
                    let angle = (Double(i) / Double(petalCount)) * 2.0 * Double.pi
                    let isOpen = i < min(max(openCount, 0), petalCount)

                    // Stable micro-variation (deterministic; no randomness)
                    let wobbleA = CGFloat(sin(Double(i) * 0.55))
                    let wobbleB = CGFloat(cos(Double(i) * 0.37))
                    let w = basePetalWidth * (1.0 + 0.10 * wobbleA)
                    let l = basePetalLength * (1.0 + 0.04 * wobbleB)

                    PetalShape()
                        .fill(petalFill(isOpen: isOpen))
                        .overlay(
                            PetalShape()
                                .stroke(.primary.opacity(isOpen ? 0.18 : 0.08), lineWidth: 1)
                        )
                        .shadow(
                            color: .black.opacity(isOpen ? 0.06 : 0.00),
                            radius: isOpen ? 1.2 : 0,
                            x: 0,
                            y: isOpen ? 0.8 : 0
                        )
                        .frame(width: w, height: l)
                        .offset(y: -innerRadius - l / 2)
                        .rotationEffect(.radians(angle))
                        .scaleEffect(isOpen ? 1.0 : 0.94)
                }

                Button(action: onPortraitTap) {
                    PortraitView(recipe: portraitRecipe)
                }
                .buttonStyle(.plain)
                .frame(width: size * 0.40, height: size * 0.40) // tweak as desired
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.vertical, 12)
    }

    private func petalFill(isOpen: Bool) -> LinearGradient {
        // Subtle form: slightly darker at base, lighter towards tip
        let top = Color.primary.opacity(isOpen ? 0.14 : 0.035)
        let base = Color.primary.opacity(isOpen ? 0.22 : 0.06)

        return LinearGradient(
            colors: [top, base],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: h * 0.65), control: CGPoint(x: w, y: h * 0.20))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.75, y: h * 0.98))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.65), control: CGPoint(x: w * 0.25, y: h * 0.98))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: 0, y: h * 0.20))
        return p
    }
}
