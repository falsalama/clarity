import SwiftUI

struct PortraitView: View {
    let recipe: PortraitRecipe

    // All geometry below is authored for this canvas, then scaled as a single unit.
    private let designSize: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let scale = side / designSize

            ZStack {
                backgroundLayer
                robeLayer
                faceLayer
                hairLayer
                glassesLayer
                hatLayer
            }
            .frame(width: designSize, height: designSize)
            .scaleEffect(scale, anchor: .center)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.primary.opacity(0.10), lineWidth: 1))
        .accessibilityLabel("Portrait")
    }

    // MARK: Background

    private var backgroundLayer: some View {
        ZStack {
            if let c = PortraitPalette.background(recipe.backgroundStyle) {
                Circle()
                    .fill(c.opacity(0.35))
                    .blur(radius: recipe.backgroundStyle == .halo ? 10 : 0)
            }
        }
    }

    // MARK: Face

    private var faceLayer: some View {
        ZStack {
            faceShape
                .fill(PortraitPalette.skin(recipe.skinTone))

            HStack(spacing: 24) {
                eyeDot
                eyeDot
            }
            .offset(y: -6)

            browsLayer
            mouthLayer
        }
        .padding(18)
    }

    private var faceShape: some Shape {
        switch recipe.faceShape {
        case .slim:
            return AnyShape(Ellipse().inset(by: 2))
        case .standard:
            return AnyShape(Circle())
        case .round:
            return AnyShape(Circle().inset(by: -2))
        }
    }

    private var eyeDot: some View {
        Circle()
            .fill(PortraitPalette.eyes(recipe.eyeColour))
            .frame(width: 8, height: 8)
    }

    private var browsLayer: some View {
        let opacity = Color.primary.opacity(0.18)
        let y: CGFloat = -16

        switch recipe.expression {
        case .neutral:
            return AnyView(
                HStack(spacing: 18) {
                    Capsule().fill(opacity).frame(width: 16, height: 2)
                    Capsule().fill(opacity).frame(width: 16, height: 2)
                }.offset(y: y)
            )

        case .soft:
            return AnyView(
                HStack(spacing: 18) {
                    Capsule().fill(opacity).frame(width: 16, height: 2).rotationEffect(.degrees(-8))
                    Capsule().fill(opacity).frame(width: 16, height: 2).rotationEffect(.degrees(8))
                }.offset(y: y)
            )

        case .fierce:
            return AnyView(
                HStack(spacing: 18) {
                    Capsule().fill(opacity).frame(width: 16, height: 2).rotationEffect(.degrees(14))
                    Capsule().fill(opacity).frame(width: 16, height: 2).rotationEffect(.degrees(-14))
                }.offset(y: y)
            )
        }
    }

    private var mouthLayer: some View {
        let base = Color.primary.opacity(0.25)

        switch recipe.expression {
        case .neutral:
            return AnyView(
                Capsule().fill(base).frame(width: 18, height: 3).offset(y: 14)
            )
        case .soft:
            return AnyView(
                Capsule().fill(base).frame(width: 18, height: 3)
                    .rotationEffect(.degrees(-6))
                    .offset(y: 14)
            )
        case .fierce:
            return AnyView(
                Capsule().fill(base).frame(width: 18, height: 3)
                    .rotationEffect(.degrees(10))
                    .offset(y: 14)
            )
        }
    }

    // MARK: Robe

    private var robeLayer: some View {
        let robeMain = PortraitPalette.robe(recipe.robeColour)

        return ZStack {
            switch recipe.robeStyle {
            case .lay:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(robeMain)
                    .frame(width: 120, height: 62)
                    .offset(y: 38)

            case .robeA:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(robeMain)
                    .frame(width: 120, height: 66)
                    .offset(y: 40)
                Rectangle()
                    .fill(.black.opacity(0.12))
                    .frame(width: 36, height: 66)
                    .offset(x: -18, y: 40)

            case .robeB:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(robeMain)
                    .frame(width: 120, height: 66)
                    .offset(y: 40)
                Rectangle()
                    .fill(.black.opacity(0.10))
                    .frame(width: 44, height: 10)
                    .offset(y: 22)

            case .ngakpa:
                let maroon = PortraitPalette.robe(.maroon)
                let offWhite = PortraitPalette.robe(.white)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(maroon)
                    .frame(width: 120, height: 66)
                    .offset(y: 40)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(offWhite.opacity(0.95))
                    .frame(width: 34, height: 52)
                    .offset(x: -22, y: 44)

                Rectangle()
                    .fill(.black.opacity(0.10))
                    .frame(width: 44, height: 10)
                    .offset(y: 22)
            }
        }
    }

    // MARK: Hair

    private var hairLayer: some View {
        let hair = PortraitPalette.hair(recipe.hairColour)

        return ZStack {
            switch recipe.hairStyle {
            case .shaved:
                EmptyView()

            case .short:
                shortHair(color: hair)

            case .shoulder:
                hairCap(color: hair)
                shoulderHair(color: hair)

            case .bun:
                hairCap(color: hair)
                bun(color: hair)

            case .topknot:
                hairCap(color: hair)
                yogiTopknot(color: hair)

            case .longStraight:
                hairCap(color: hair)
                longHair(color: hair, wave: 0)

            case .longWavy:
                hairCap(color: hair)
                longHair(color: hair, wave: 1)

            case .longCurls:
                hairCap(color: hair)
                longHair(color: hair, wave: 2)

            case .tiedBack:
                hairCap(color: hair)
                tiedBack(color: hair)
            }
        }
    }

    private func hairCap(color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: 92, height: 18)
            .offset(y: -52)
            .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }

    private func shortHair(color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(color)
                .frame(width: 112, height: 44)
                .offset(y: -2)
                .mask(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .frame(width: 112, height: 44)
                        .offset(y: -2)
                        .overlay {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 110, height: 110)
                                .offset(y: -14)
                                .blendMode(.destinationOut)
                        }
                )

            HairlineArc()
                .stroke(Color.black.opacity(0.12), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 58, height: 18)
                .offset(y: -6)
        }
        .compositingGroup()
    }

    private func shoulderHair(color: Color) -> some View {
        HStack(spacing: 44) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 26, height: 46)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 26, height: 46)
        }
        .offset(y: -10)
    }

    private func bun(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
                .offset(y: -68)

            Capsule()
                .fill(color.opacity(0.95))
                .frame(width: 10, height: 6)
                .offset(y: -60)
        }
    }

    private func yogiTopknot(color: Color) -> some View {
        ZStack {
            Capsule()
                .fill(color.opacity(0.95))
                .frame(width: 14, height: 8)
                .offset(y: -64)

            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .offset(y: -74)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 6, height: 12)
                .offset(y: -84)
        }
    }

    private func longHair(color: Color, wave: Int) -> some View {
        let width: CGFloat = 112
        let height: CGFloat = 72

        return ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(color)
                .frame(width: width, height: height)
                .offset(y: 6)
                .mask(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .frame(width: width, height: height)
                        .offset(y: 6)
                        .overlay(alignment: .top) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 110, height: 110)
                                .offset(y: -26)
                                .blendMode(.destinationOut)
                        }
                )

            if wave == 1 {
                HStack(spacing: 10) {
                    Capsule().fill(.white.opacity(0.10)).frame(width: 8, height: 56)
                    Capsule().fill(.white.opacity(0.08)).frame(width: 6, height: 50)
                }
                .offset(x: -26, y: 14)
            } else if wave == 2 {
                HStack(spacing: 12) {
                    VStack(spacing: 10) {
                        Circle().fill(.white.opacity(0.10)).frame(width: 6, height: 6)
                        Circle().fill(.white.opacity(0.08)).frame(width: 6, height: 6)
                        Circle().fill(.white.opacity(0.06)).frame(width: 6, height: 6)
                    }
                    VStack(spacing: 10) {
                        Circle().fill(.white.opacity(0.10)).frame(width: 6, height: 6)
                        Circle().fill(.white.opacity(0.08)).frame(width: 6, height: 6)
                        Circle().fill(.white.opacity(0.06)).frame(width: 6, height: 6)
                    }
                }
                .offset(x: -30, y: 16)
            }
        }
        .compositingGroup()
    }

    private func tiedBack(color: Color) -> some View {
        ZStack {
            HStack(spacing: 56) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color)
                    .frame(width: 18, height: 34)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color)
                    .frame(width: 18, height: 34)
            }
            .offset(y: -12)

            Capsule()
                .fill(color)
                .frame(width: 16, height: 8)
                .offset(y: -60)
        }
    }

    // MARK: Glasses

    private var glassesLayer: some View {
        guard let style = recipe.glassesStyle else { return AnyView(EmptyView()) }

        let stroke = Color.primary.opacity(0.32)
        let thin = (style == .roundThin || style == .squareThin) ? 1.5 : 2.5

        func roundFrame() -> some View {
            HStack(spacing: 12) {
                Circle().stroke(stroke, lineWidth: thin).frame(width: 18, height: 18)
                Circle().stroke(stroke, lineWidth: thin).frame(width: 18, height: 18)
            }
            .overlay(Rectangle().fill(stroke).frame(width: 10, height: thin))
            .offset(y: -6)
        }

        func squareFrame() -> some View {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4).stroke(stroke, lineWidth: thin).frame(width: 18, height: 14)
                RoundedRectangle(cornerRadius: 4).stroke(stroke, lineWidth: thin).frame(width: 18, height: 14)
            }
            .overlay(Rectangle().fill(stroke).frame(width: 10, height: thin))
            .offset(y: -6)
        }

        func hexFrame() -> some View {
            HStack(spacing: 12) {
                Hexagon().stroke(stroke, lineWidth: thin).frame(width: 18, height: 18)
                Hexagon().stroke(stroke, lineWidth: thin).frame(width: 18, height: 18)
            }
            .overlay(Rectangle().fill(stroke).frame(width: 10, height: thin))
            .offset(y: -6)
        }

        switch style {
        case .round, .roundThin:
            return AnyView(roundFrame())
        case .square, .squareThin:
            return AnyView(squareFrame())
        case .hex:
            return AnyView(hexFrame())
        }
    }

    // MARK: Hats

    private var hatLayer: some View {
        guard let hat = recipe.hatStyle else { return AnyView(EmptyView()) }

        switch hat {
        case .conicalStraw:
            return AnyView(conicalHat)
        case .patternedCap:
            return AnyView(patternedCap)
        case .monasticCap:
            return AnyView(monasticCap)
        }
    }

    private var conicalHat: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.14))
                .frame(width: 118, height: 28)
                .offset(y: -60)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.black.opacity(0.16))
                .frame(width: 54, height: 20)
                .offset(y: -72)

            Capsule()
                .fill(.white.opacity(0.16))
                .frame(width: 34, height: 3)
                .offset(x: -6, y: -74)
        }
    }

    private var patternedCap: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.black.opacity(0.18))
                .frame(width: 80, height: 22)
                .offset(y: -64)

            HStack(spacing: 6) {
                Capsule().fill(.white.opacity(0.14)).frame(width: 6, height: 14)
                Capsule().fill(.white.opacity(0.10)).frame(width: 6, height: 14)
                Capsule().fill(.white.opacity(0.14)).frame(width: 6, height: 14)
            }
            .offset(y: -64)
        }
    }

    private var monasticCap: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PortraitPalette.robe(.saffron).opacity(0.95))
                .frame(width: 62, height: 18)
                .offset(y: -64)

            Capsule()
                .fill(.black.opacity(0.10))
                .frame(width: 46, height: 3)
                .offset(y: -60)
        }
    }
}

// MARK: - Helpers

private struct AnyShape: Shape {
    // Make the stored closure Sendable so the type-erased shape can be Sendable.
    private let _path: @Sendable (CGRect) -> Path

    // Require the captured shape to be Sendable so the @Sendable closure is valid.
    init<S: Shape & Sendable>(_ s: S) {
        _path = { rect in s.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path { _path(rect) }
}

private struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let pts = [
            CGPoint(x: w * 0.25, y: 0),
            CGPoint(x: w * 0.75, y: 0),
            CGPoint(x: w, y: h * 0.5),
            CGPoint(x: w * 0.75, y: h),
            CGPoint(x: w * 0.25, y: h),
            CGPoint(x: 0, y: h * 0.5),
        ]
        var p = Path()
        p.move(to: pts[0])
        for i in 1..<pts.count { p.addLine(to: pts[i]) }
        p.closeSubpath()
        return p
    }
}

private struct HairlineArc: Shape {
    func path(in rect: CGRect) -> Path {
        let left = CGPoint(x: rect.minX, y: rect.midY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)
        let control = CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.35)
        var p = Path()
        p.move(to: left)
        p.addQuadCurve(to: right, control: control)
        return p
    }
}
