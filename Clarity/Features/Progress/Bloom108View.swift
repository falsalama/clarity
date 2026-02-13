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
            let petalLength = outerRadius - innerRadius
            let petalWidth = size * 0.035

            ZStack {
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

                VStack(spacing: 8) {
                    Button(action: onPortraitTap) {
                        ZStack {
                            Circle()
                                .fill(.primary.opacity(0.06))
                                .overlay(Circle().stroke(.primary.opacity(0.10), lineWidth: 1))

                            PortraitView(recipe: portraitRecipe)
                                .padding(size * 0.02)
                        }
                    }
                    .buttonStyle(.plain)
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
