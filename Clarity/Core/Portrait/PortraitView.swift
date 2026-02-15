// PortraitView.swift

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

                // Hair must be split: back behind face, front on top of face.
                hairBackLayer

                faceLayer

                hairFrontLayer

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
                Circle().fill(c.opacity(0.22))
            }

            if recipe.backgroundStyle == .halo {
                Circle()
                    .strokeBorder(Color.yellow.opacity(0.30), lineWidth: 10)
                    .blur(radius: 4)
                    .padding(6)

                Circle()
                    .strokeBorder(Color.yellow.opacity(0.18), lineWidth: 2)
                    .padding(10)
            }

            if recipe.backgroundStyle == .lotus {
                SparklesLayer()
                    .opacity(0.55)
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
        case .slim:      return AnyShape(ScaledEllipse(xScale: 0.86, yScale: 1.00))
        case .standard:  return AnyShape(ScaledEllipse(xScale: 0.93, yScale: 1.00))
        case .round:     return AnyShape(ScaledEllipse(xScale: 1.00, yScale: 1.00))
        }
    }

    private var eyeDot: some View {
        Circle()
            .fill(PortraitPalette.eyes(recipe.eyeColour))
            .frame(width: 8, height: 8)
    }

    private var browsLayer: some View {
        let tint = Color.primary.opacity(0.18)
        let y: CGFloat = -16

        switch recipe.expression {
        case .serene:
            return AnyView(
                HStack(spacing: 18) {
                    Capsule().fill(tint).frame(width: 16, height: 2)
                    Capsule().fill(tint).frame(width: 16, height: 2)
                }
                .offset(y: y)
            )

        case .littleSmile:
            return AnyView(
                HStack(spacing: 18) {
                    Capsule().fill(tint).frame(width: 16, height: 2).rotationEffect(.degrees(-6))
                    Capsule().fill(tint).frame(width: 16, height: 2).rotationEffect(.degrees(6))
                }
                .offset(y: y)
            )

        case .bigSmile:
            return AnyView(
                HStack(spacing: 18) {
                    Capsule().fill(tint).frame(width: 16, height: 2).rotationEffect(.degrees(-10))
                    Capsule().fill(tint).frame(width: 16, height: 2).rotationEffect(.degrees(10))
                }
                .offset(y: y)
            )
        }
    }

    private var mouthLayer: some View {
        let stroke = Color.primary.opacity(0.25)
        let mouthY: CGFloat = 19

        switch recipe.expression {
        case .serene:
            return AnyView(
                SmileArc(curvature: 0.10)
                    .stroke(stroke, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 22, height: 12)
                    .offset(y: mouthY)
            )

        case .littleSmile:
            return AnyView(
                SmileArc(curvature: 0.30)
                    .stroke(stroke, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 24, height: 14)
                    .offset(y: mouthY)
            )

        case .bigSmile:
            return AnyView(
                SmileArc(curvature: 0.55)
                    .stroke(stroke, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 26, height: 16)
                    .offset(y: mouthY)
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

                Capsule()
                    .fill(.black.opacity(0.08))
                    .frame(width: 46, height: 6)
                    .offset(y: 20)

            case .robeA:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(robeMain)
                    .frame(width: 120, height: 66)
                    .offset(y: 40)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.black.opacity(0.14))
                    .frame(width: 44, height: 70)
                    .offset(x: -22, y: 40)

                Capsule()
                    .fill(.black.opacity(0.10))
                    .frame(width: 54, height: 6)
                    .offset(y: 20)

            case .robeB:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(robeMain)
                    .frame(width: 120, height: 66)
                    .offset(y: 40)

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.black.opacity(0.12))
                    .frame(width: 88, height: 12)
                    .offset(y: 26)

                Capsule()
                    .fill(.black.opacity(0.08))
                    .frame(width: 56, height: 4)
                    .offset(y: 18)
            }

            if recipe.robeColour == .maroon {
                twoToneBand
                    .mask(robeMask(for: recipe.robeStyle))
            }
        }
    }

    private var twoToneBand: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white)
                .frame(width: 140, height: 12)
                .rotationEffect(.degrees(-24))
                .offset(x: 6, y: 28)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                .frame(width: 140, height: 12)
                .rotationEffect(.degrees(-24))
                .offset(x: 6, y: 28)
        }
    }

    private func robeMask(for style: RobeStyleID) -> some View {
        switch style {
        case .lay:
            return AnyView(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .frame(width: 120, height: 62)
                    .offset(y: 38)
            )
        case .robeA, .robeB:
            return AnyView(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .frame(width: 120, height: 66)
                    .offset(y: 40)
            )
        }
    }

    // MARK: Hair

    private var hairWidthScale: CGFloat {
        switch recipe.faceShape {
        case .slim: return 0.92
        case .standard: return 1.00
        case .round: return 1.04
        }
    }

    private var hairColor: Color { PortraitPalette.hair(recipe.hairColour) }

    /// Hair behind face (mass, length).
    private var hairBackLayer: some View {
        let c = hairColor

        return ZStack {
            switch recipe.hairStyle {
            case .shaved:
                EmptyView()

            case .short:
                EmptyView()

            case .shoulder:
                BackHairMassShape(length: .shoulder)
                    .fill(c)
                    .frame(width: 116 * hairWidthScale, height: 92)
                    .offset(y: 0)

            case .bun:
                BackHairMassShape(length: .shoulder)
                    .fill(c)
                    .frame(width: 116 * hairWidthScale, height: 92)
                    .offset(y: 0)

            case .topknot:
                EmptyView()

            case .longStraight:
                BackHairMassShape(length: .longStraight)
                    .fill(c)
                    .frame(width: 122 * hairWidthScale, height: 100)
                    .offset(y: 4)

            case .longWavy:
                BackHairMassShape(length: .longWavy)
                    .fill(c)
                    .frame(width: 124 * hairWidthScale, height: 102)
                    .offset(y: 4)

                VStack(spacing: 10) {
                    Capsule().fill(Color.white.opacity(0.06)).frame(width: 10, height: 46)
                    Capsule().fill(Color.white.opacity(0.05)).frame(width: 8, height: 40)
                }
                .offset(x: -26 * hairWidthScale, y: 22)

            case .longCurls:
                BackHairMassShape(length: .longCurls)
                    .fill(c)
                    .frame(width: 126 * hairWidthScale, height: 104)
                    .offset(y: 6)

                VStack(spacing: 8) {
                    Circle().fill(Color.white.opacity(0.06)).frame(width: 6, height: 6)
                    Circle().fill(Color.white.opacity(0.05)).frame(width: 6, height: 6)
                    Circle().fill(Color.white.opacity(0.04)).frame(width: 6, height: 6)
                }
                .offset(x: -28 * hairWidthScale, y: 26)

            case .tiedBack:
                BackHairMassShape(length: .tiedBack)
                    .fill(c)
                    .frame(width: 118 * hairWidthScale, height: 96)
                    .offset(y: 2)
            }
        }
    }

    /// Hair in front of face (cap + fringe/curtains only).
    private var hairFrontLayer: some View {
        let c = hairColor

        return ZStack {
            switch recipe.hairStyle {
            case .shaved:
                EmptyView()

            case .short:
                shortFront(color: c)

            case .shoulder:
                cap(color: c)
                curtainsFront(style: .shoulder, color: c)

            case .bun:
                cap(color: c)
                curtainsFront(style: .shoulder, color: c)
                sideBun(color: c)

            case .topknot:
                topknotFront(color: c)

            case .longStraight:
                cap(color: c)
                curtainsFront(style: .longStraight, color: c)

            case .longWavy:
                cap(color: c)
                curtainsFront(style: .longWavy, color: c)

            case .longCurls:
                cap(color: c)
                curtainsFront(style: .longCurls, color: c)

            case .tiedBack:
                cap(color: c)
                curtainsFront(style: .tiedBack, color: c)
            }
        }
    }

    private func cap(color: Color) -> some View {
        HairCapShape()
            .fill(color)
            .frame(width: 108 * hairWidthScale, height: 72)
            .offset(y: -30)
            .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }

    private func shortFront(color: Color) -> some View {
        ZStack {
            HairCapShape()
                .fill(color)
                .frame(width: 104 * hairWidthScale, height: 76)
                .offset(y: -32)

            // Straight fringe band (flat across, no centre point)
            StraightFringeBandShape()
                .fill(Color.black.opacity(0.08))
                .frame(width: 86 * hairWidthScale, height: 14)
                .offset(y: -22)
        }
    }

    private func topknotFront(color: Color) -> some View {
        ZStack {
            cap(color: color)

            TopknotShape()
                .fill(color)
                .frame(width: 18, height: 28)
                .offset(y: -62)

            Capsule()
                .fill(Color.black.opacity(0.10))
                .frame(width: 16, height: 4)
                .offset(y: -52)
        }
    }

    private func sideBun(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .offset(x: 16, y: -58)

            Capsule()
                .fill(Color.black.opacity(0.10))
                .frame(width: 16, height: 4)
                .offset(x: 16, y: -50)
        }
    }

    private enum CurtainStyle { case shoulder, longStraight, longWavy, longCurls, tiedBack }

    private func curtainsFront(style: CurtainStyle, color: Color) -> some View {
        let (w, h, x, y, curve, curl) : (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) = {
            switch style {
            case .shoulder:     return (44, 56, 30, -2, 0.10, 0.00)
            case .longStraight: return (46, 64, 30,  0, 0.12, 0.00)
            case .longWavy:     return (46, 66, 30,  0, 0.18, 0.00)
            case .longCurls:    return (48, 68, 30,  2, 0.20, 0.18)
            case .tiedBack:     return (40, 52, 34, -4, 0.10, 0.00)
            }
        }()

        return ZStack {
            FrontCurtainShape(isLeft: true, curve: curve, curl: curl)
                .fill(color)
                .frame(width: w * hairWidthScale, height: h)
                .offset(x: -x * hairWidthScale, y: y)

            FrontCurtainShape(isLeft: false, curve: curve, curl: curl)
                .fill(color)
                .frame(width: w * hairWidthScale, height: h)
                .offset(x: x * hairWidthScale, y: y)
        }
        // important: keep centre of face clear
        .mask(
            Rectangle()
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .frame(width: 96 * hairWidthScale, height: 108)
                        .offset(y: -4)
                        .blendMode(.destinationOut)
                )
                .compositingGroup()
        )
        .compositingGroup()
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
        case .round, .roundThin:   return AnyView(roundFrame())
        case .square, .squareThin: return AnyView(squareFrame())
        case .hex:                 return AnyView(hexFrame())
        }
    }

    // MARK: Hats (anchor to head)

    private var hatLayer: some View {
        guard let hat = recipe.hatStyle else { return AnyView(EmptyView()) }

        switch hat {
        case .conicalStraw:  return AnyView(conicalHat)
        case .patternedCap:  return AnyView(patternedCap)
        case .monasticCap:   return AnyView(monasticCap)
        }
    }

    private var hatAnchorY: CGFloat { -78 }

    private var conicalHat: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.14))
                .frame(width: 112 * hairWidthScale, height: 22)
                .offset(y: hatAnchorY + 10)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.black.opacity(0.18))
                .frame(width: 54, height: 20)
                .offset(y: hatAnchorY)

            Capsule()
                .fill(.white.opacity(0.16))
                .frame(width: 34, height: 3)
                .offset(x: -6, y: hatAnchorY - 2)
        }
        .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
    }

    private var patternedCap: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.black.opacity(0.18))
                .frame(width: 82, height: 22)
                .offset(y: hatAnchorY)

            HStack(spacing: 6) {
                Capsule().fill(.white.opacity(0.14)).frame(width: 6, height: 14)
                Capsule().fill(.white.opacity(0.10)).frame(width: 6, height: 14)
                Capsule().fill(.white.opacity(0.14)).frame(width: 6, height: 14)
            }
            .offset(y: hatAnchorY)
        }
        .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
    }

    private var monasticCap: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(PortraitPalette.robe(.saffron).opacity(0.95))
                .frame(width: 66, height: 18)
                .offset(y: hatAnchorY + 2)

            Capsule()
                .fill(.black.opacity(0.10))
                .frame(width: 48, height: 3)
                .offset(y: hatAnchorY + 6)
        }
        .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
    }
}

// MARK: - Helpers

private struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path
    init<S: Shape & Sendable>(_ s: S) { _path = { rect in s.path(in: rect) } }
    func path(in rect: CGRect) -> Path { _path(rect) }
}

private struct ScaledEllipse: Shape, Sendable {
    let xScale: CGFloat
    let yScale: CGFloat
    func path(in rect: CGRect) -> Path {
        let w = rect.width * xScale
        let h = rect.height * yScale
        let r = CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
        return Ellipse().path(in: r)
    }
}

private struct SmileArc: Shape, Sendable {
    let curvature: CGFloat
    func path(in rect: CGRect) -> Path {
        let left = CGPoint(x: rect.minX, y: rect.midY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)
        let lift = rect.height * curvature
        let control = CGPoint(x: rect.midX, y: rect.midY + lift)
        var p = Path()
        p.move(to: left)
        p.addQuadCurve(to: right, control: control)
        return p
    }
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

// MARK: - Background sparkles

private struct SparklesLayer: View {
    var body: some View {
        ZStack {
            sparkle(x: -34, y: -30, s: 10, o: 0.18)
            sparkle(x: 28, y: -26, s: 7, o: 0.16)
            sparkle(x: -18, y: 18, s: 6, o: 0.12)
            sparkle(x: 34, y: 20, s: 9, o: 0.14)
            sparkle(x: 0, y: -44, s: 5, o: 0.10)
        }
    }

    private func sparkle(x: CGFloat, y: CGFloat, s: CGFloat, o: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(o))
            .frame(width: s, height: s)
            .blur(radius: 0.5)
            .offset(x: x, y: y)
    }
}

// MARK: - Hair shapes

private struct HairCapShape: Shape, Sendable {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let top = rect.minY
        let left = rect.minX
        let right = rect.maxX
        let midX = rect.midX

        let hairlineY = rect.minY + h * 0.54

        var p = Path()
        p.move(to: CGPoint(x: left + w * 0.10, y: hairlineY))
        p.addQuadCurve(
            to: CGPoint(x: midX, y: hairlineY + h * 0.06),
            control: CGPoint(x: midX - w * 0.20, y: hairlineY - h * 0.12)
        )
        p.addQuadCurve(
            to: CGPoint(x: right - w * 0.10, y: hairlineY),
            control: CGPoint(x: midX + w * 0.20, y: hairlineY - h * 0.12)
        )

        p.addQuadCurve(
            to: CGPoint(x: right - w * 0.16, y: top + h * 0.12),
            control: CGPoint(x: right, y: top + h * 0.34)
        )

        p.addQuadCurve(
            to: CGPoint(x: left + w * 0.16, y: top + h * 0.12),
            control: CGPoint(x: midX, y: top - h * 0.08)
        )

        p.addQuadCurve(
            to: CGPoint(x: left + w * 0.10, y: hairlineY),
            control: CGPoint(x: left, y: top + h * 0.34)
        )

        p.closeSubpath()
        return p
    }
}

private struct StraightFringeBandShape: Shape, Sendable {
    func path(in rect: CGRect) -> Path {
        _ = rect.width
        let h = rect.height
        let yTop = rect.minY + h * 0.30
        let yBottom = rect.maxY

        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: yTop))
        p.addLine(to: CGPoint(x: rect.maxX, y: yTop))
        p.addLine(to: CGPoint(x: rect.maxX, y: yBottom))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: yBottom),
            control: CGPoint(x: rect.midX, y: yBottom + h * 0.18)
        )
        p.closeSubpath()
        return p
    }
}

private struct TopknotShape: Shape, Sendable {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        var p = Path()
        p.move(to: CGPoint(x: rect.minX + w * 0.18, y: rect.midY))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + h * 0.06),
            control: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.12)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - w * 0.18, y: rect.midY),
            control: CGPoint(x: rect.maxX - w * 0.28, y: rect.minY + h * 0.12)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.04),
            control: CGPoint(x: rect.maxX - w * 0.22, y: rect.maxY)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + w * 0.18, y: rect.midY),
            control: CGPoint(x: rect.minX + w * 0.22, y: rect.maxY)
        )
        p.closeSubpath()
        return p
    }
}

private enum HairLengthKind { case shoulder, longStraight, longWavy, longCurls, tiedBack }

private struct BackHairMassShape: Shape, Sendable {
    let length: HairLengthKind

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let top = rect.minY
        let left = rect.minX
        let right = rect.maxX
        let bottom = rect.maxY

        let (shoulderY, bottomLift, sway, scallop): (CGFloat, CGFloat, CGFloat, CGFloat) = {
            switch length {
            case .shoulder:    return (top + h * 0.74, h * 0.06, 0.02, 0.00)
            case .tiedBack:    return (top + h * 0.70, h * 0.08, 0.00, 0.00)
            case .longStraight:return (top + h * 0.84, h * 0.02, 0.00, 0.00)
            case .longWavy:    return (top + h * 0.86, h * 0.02, 0.10, 0.00)
            case .longCurls:   return (top + h * 0.88, h * 0.00, 0.12, 0.20)
            }
        }()

        var p = Path()
        p.move(to: CGPoint(x: left + w * 0.20, y: top + h * 0.22))

        p.addCurve(
            to: CGPoint(x: left + w * (0.10 + sway), y: shoulderY),
            control1: CGPoint(x: left + w * 0.08, y: top + h * 0.40),
            control2: CGPoint(x: left + w * 0.05, y: top + h * 0.62)
        )

        if scallop > 0 {
            let y = bottom - bottomLift
            p.addQuadCurve(
                to: CGPoint(x: left + w * 0.34, y: y),
                control: CGPoint(x: left + w * 0.16, y: bottom + h * scallop)
            )
            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.34, y: y),
                control: CGPoint(x: rect.midX, y: bottom + h * scallop * 0.9)
            )
            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.10 - sway * w, y: shoulderY),
                control: CGPoint(x: right - w * 0.16, y: bottom + h * scallop)
            )
        } else {
            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.10 - sway * w, y: shoulderY),
                control: CGPoint(x: rect.midX, y: bottom + h * 0.06)
            )
        }

        p.addCurve(
            to: CGPoint(x: right - w * 0.20, y: top + h * 0.22),
            control1: CGPoint(x: right - w * 0.05, y: top + h * 0.62),
            control2: CGPoint(x: right - w * 0.08, y: top + h * 0.40)
        )

        p.addQuadCurve(
            to: CGPoint(x: left + w * 0.20, y: top + h * 0.22),
            control: CGPoint(x: rect.midX, y: top + h * 0.08)
        )

        p.closeSubpath()
        return p
    }
}

private struct FrontCurtainShape: Shape, Sendable {
    let isLeft: Bool
    let curve: CGFloat
    let curl: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let top = rect.minY
        let bottom = rect.maxY

        let outerX = isLeft ? rect.minX : rect.maxX
        let innerX = isLeft ? rect.maxX : rect.minX

        // Keep away from the centre so it never forms a middle spike.
        let innerInset = w * 0.40

        // Concave top: centre higher, sides lower.
        let topInner = CGPoint(
            x: innerX + (isLeft ? -innerInset : innerInset),
            y: top + h * 0.06
        )
        let topOuter = CGPoint(
            x: outerX,
            y: top + h * 0.18
        )

        var p = Path()
        p.move(to: topInner)

        p.addQuadCurve(
            to: topOuter,
            control: CGPoint(
                x: (topInner.x + topOuter.x) * 0.5,
                y: top + h * 0.02
            )
        )

        p.addCurve(
            to: CGPoint(x: outerX, y: bottom - h * 0.10),
            control1: CGPoint(x: outerX, y: top + h * (0.30 + curve)),
            control2: CGPoint(x: outerX, y: top + h * (0.62 + curve))
        )

        let curlLift = h * curl
        p.addQuadCurve(
            to: CGPoint(x: innerX, y: bottom),
            control: CGPoint(x: rect.midX, y: bottom + curlLift)
        )

        p.addQuadCurve(
            to: topInner,
            control: CGPoint(
                x: innerX + (isLeft ? -innerInset * 0.85 : innerInset * 0.85),
                y: top + h * 0.56
            )
        )

        p.closeSubpath()
        return p
    }
}

