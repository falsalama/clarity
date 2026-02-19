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
                layRobe(fill: robeMain)
            case .robeA:
                monasticRobeA(fill: robeMain)
            case .robeB:
                monasticRobeB(fill: robeMain)
            }

            if recipe.robeColour == .maroon {
                twoToneBand
                    .mask(robeMask(for: recipe.robeStyle))
            }
        }
        .compositingGroup()
    }

    private func layRobe(fill: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fill)
                .frame(width: 128, height: 66)
                .offset(y: 40)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fill)
                .frame(width: 128, height: 66)
                .offset(y: 40)
                .overlay(
                    VNeckCutout()
                        .fill(.black)
                        .frame(width: 46, height: 34)
                        .offset(y: 22)
                        .blendMode(.destinationOut)
                )
                .compositingGroup()

            VNeckStroke()
                .stroke(.white.opacity(0.18), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 46, height: 34)
                .offset(y: 22)

            Capsule()
                .fill(.black.opacity(0.10))
                .frame(width: 58, height: 6)
                .offset(y: 22)
        }
    }

    private func monasticRobeA(fill: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fill)
                .frame(width: 124, height: 70)
                .offset(y: 42)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.black.opacity(0.18))
                .frame(width: 46, height: 76)
                .offset(x: -26, y: 42)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(.black.opacity(0.12))
                .frame(width: 150, height: 14)
                .rotationEffect(.degrees(-22))
                .offset(x: 8, y: 32)

            Capsule()
                .fill(.black.opacity(0.12))
                .frame(width: 64, height: 6)
                .offset(y: 20)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.white.opacity(0.10))
                .frame(width: 54, height: 10)
                .rotationEffect(.degrees(-18))
                .offset(x: -18, y: 28)
        }
    }

    private func monasticRobeB(fill: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fill)
                .frame(width: 124, height: 70)
                .offset(y: 42)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.black.opacity(0.14))
                .frame(width: 54, height: 78)
                .offset(y: 42)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.black.opacity(0.12))
                .frame(width: 98, height: 14)
                .offset(y: 28)

            Capsule()
                .fill(.black.opacity(0.10))
                .frame(width: 52, height: 4)
                .offset(y: 18)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.08))
                .frame(width: 18, height: 62)
                .offset(x: -10, y: 44)
        }
    }

    private var twoToneBand: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white)
                .frame(width: 150, height: 12)
                .rotationEffect(.degrees(-24))
                .offset(x: 6, y: 30)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
                .frame(width: 150, height: 12)
                .rotationEffect(.degrees(-24))
                .offset(x: 6, y: 30)
        }
    }

    private func robeMask(for style: RobeStyleID) -> some View {
        switch style {
        case .lay:
            return AnyView(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .frame(width: 128, height: 66)
                    .offset(y: 40)
            )
        case .robeA, .robeB:
            return AnyView(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .frame(width: 124, height: 70)
                    .offset(y: 42)
            )
        }
    }

    // MARK: Robe neckline helper shapes

    private struct VNeckCutout: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            let midX = rect.midX

            p.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.08))
            p.addLine(to: CGPoint(x: midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.08))
            p.addQuadCurve(
                to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.08),
                control: CGPoint(x: midX, y: rect.minY - rect.height * 0.18)
            )
            p.closeSubpath()
            return p
        }
    }

    private struct VNeckStroke: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            let midX = rect.midX

            p.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.12))
            p.addLine(to: CGPoint(x: midX, y: rect.maxY - rect.height * 0.06))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.minY + rect.height * 0.12))
            return p
        }
    }

    // MARK: Hair

    private var hairWidthScale: CGFloat {
        switch recipe.faceShape {
        case .slim: return 0.90
        case .standard: return 1.00
        case .round: return 1.08
        }
    }

    private var hairColor: Color { PortraitPalette.hair(recipe.hairColour) }

    private var crownHeightScale: CGFloat {
        switch recipe.faceShape {
        case .slim: return 1.02
        case .standard: return 1.00
        case .round: return 0.98
        }
    }

    // Hair behind face
    private var hairBackLayer: some View {
        let c = hairColor

        return ZStack {
            switch recipe.hairStyle {
            case .shaved:
                EmptyView()

            case .short:
                BackSkullShape()
                    .fill(c.opacity(0.22))
                    .frame(width: 96 * hairWidthScale, height: 64 * crownHeightScale)
                    .offset(y: -30)

            case .topknot:
                EmptyView()

            case .shoulder:
                BackHairMassShape(length: .shoulder)
                    .fill(c)
                    .frame(width: 122 * hairWidthScale, height: 96)
                    .offset(y: 4)

            case .bun:
                BackHairMassShape(length: .shoulder)
                    .fill(c)
                    .frame(width: 122 * hairWidthScale, height: 96)
                    .offset(y: 4)

            case .longStraight:
                BackHairMassShape(length: .longStraight)
                    .fill(c)
                    .frame(width: 128 * hairWidthScale, height: 112)
                    .offset(y: 14)

            case .longWavy:
                BackHairMassShape(length: .longWavy)
                    .fill(c)
                    .frame(width: 132 * hairWidthScale, height: 116)
                    .offset(y: 16)

            case .longCurls:
                BackHairMassShape(length: .longCurls)
                    .fill(c)
                    .frame(width: 134 * hairWidthScale, height: 118)
                    .offset(y: 18)

            case .tiedBack:
                BackHairMassShape(length: .tiedBack)
                    .fill(c)
                    .frame(width: 120 * hairWidthScale, height: 98)
                    .offset(y: 8)

                PonytailShape()
                    .fill(c)
                    .frame(width: 22 * hairWidthScale, height: 66)
                    .offset(x: 34 * hairWidthScale, y: 26)
            }
        }
    }

    // Hair in front of face
    private var hairFrontLayer: some View {
        let c = hairColor

        return ZStack {
            switch recipe.hairStyle {
            case .shaved:
                EmptyView()

            case .short:
                shortFront(color: c)

            case .topknot:
                topknotFront(color: c)

            case .shoulder:
                shoulderFront(color: c)

            case .bun:
                shoulderFront(color: c)
                bunTop(color: c)

            case .longStraight:
                longStraightFront(color: c)

            case .longWavy:
                longWavyFront(color: c)

            case .longCurls:
                longCurlsFront(color: c)

            case .tiedBack:
                tiedBackFront(color: c)
            }
        }
    }

    // MARK: Front builders

    private func shortFront(color: Color) -> some View {
        ZStack {
            ShortCrownShape()
                .fill(color)
                .frame(width: 110 * hairWidthScale, height: 70 * crownHeightScale)
                .offset(y: -34)

            SoftFringeShape()
                .fill(.black.opacity(0.10))
                .frame(width: 92 * hairWidthScale, height: 18)
                .offset(y: -22)
        }
    }

    private func topknotFront(color: Color) -> some View {
        ZStack {
            ShortCrownShape()
                .fill(color)
                .frame(width: 110 * hairWidthScale, height: 70 * crownHeightScale)
                .offset(y: -34)

            TopknotShape()
                .fill(color)
                .frame(width: 18, height: 28)
                .offset(y: -64)

            Capsule()
                .fill(.black.opacity(0.10))
                .frame(width: 16, height: 4)
                .offset(y: -54)
        }
    }

    // This replaces the duplicated LongCrownShape situation:
    // one crown shape only, NO centre dip, no vampire point.
    private struct CrownNoDipShape: Shape, Sendable {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            let left = rect.minX
            let right = rect.maxX
            let top = rect.minY
            let midX = rect.midX

            let hairlineY = rect.minY + h * 0.56

            var p = Path()
            p.move(to: CGPoint(x: left + w * 0.10, y: hairlineY))

            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.10, y: hairlineY),
                control: CGPoint(x: midX, y: hairlineY - h * 0.22)
            )

            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.16, y: top + h * 0.12),
                control: CGPoint(x: right, y: top + h * 0.38)
            )
            p.addQuadCurve(
                to: CGPoint(x: left + w * 0.16, y: top + h * 0.12),
                control: CGPoint(x: midX, y: top - h * 0.10)
            )
            p.addQuadCurve(
                to: CGPoint(x: left + w * 0.10, y: hairlineY),
                control: CGPoint(x: left, y: top + h * 0.38)
            )

            p.closeSubpath()
            return p
        }
    }

    private func shoulderFront(color: Color) -> some View {
        ZStack {
            CrownNoDipShape()
                .fill(color)
                .frame(width: 116 * hairWidthScale, height: 72 * crownHeightScale)
                .offset(y: -34)

            // Shoulder style: heavier, shorter locks
            frontLocks(style: .shoulder, color: color)
        }
    }

    private func longStraightFront(color: Color) -> some View {
        ZStack {
            CrownNoDipShape()
                .fill(color)
                .frame(width: 118 * hairWidthScale, height: 76 * crownHeightScale)
                .offset(y: -34)

            centrePartHighlight()
            frontLocks(style: .longStraight, color: color)
        }
    }

    private func longWavyFront(color: Color) -> some View {
        ZStack {
            CrownNoDipShape()
                .fill(color)
                .frame(width: 120 * hairWidthScale, height: 76 * crownHeightScale)
                .offset(y: -34)

            centrePartHighlight()
            frontLocks(style: .longWavy, color: color)

            WavyHighlightShape(isLeft: true)
                .fill(.white.opacity(0.10))
                .frame(width: 16 * hairWidthScale, height: 62)
                .offset(x: -36 * hairWidthScale, y: 24)

            WavyHighlightShape(isLeft: false)
                .fill(.white.opacity(0.10))
                .frame(width: 16 * hairWidthScale, height: 62)
                .offset(x: 36 * hairWidthScale, y: 24)
        }
    }

    private func longCurlsFront(color: Color) -> some View {
        ZStack {
            CrownNoDipShape()
                .fill(color)
                .frame(width: 120 * hairWidthScale, height: 76 * crownHeightScale)
                .offset(y: -34)

            centrePartHighlight()
            frontLocks(style: .longCurls, color: color)

            CurlClusterShape()
                .fill(.white.opacity(0.10))
                .frame(width: 22 * hairWidthScale, height: 54)
                .offset(x: -38 * hairWidthScale, y: 28)

            CurlClusterShape()
                .fill(.white.opacity(0.10))
                .frame(width: 22 * hairWidthScale, height: 54)
                .offset(x: 38 * hairWidthScale, y: 28)
        }
    }

    private func tiedBackFront(color: Color) -> some View {
        ZStack {
            SweptBackCrownShape()
                .fill(color)
                .frame(width: 116 * hairWidthScale, height: 72 * crownHeightScale)
                .offset(y: -34)

            Capsule()
                .fill(.black.opacity(0.10))
                .frame(width: 62 * hairWidthScale, height: 4)
                .offset(y: -46)

            TempleWispShape(isLeft: true)
                .fill(color)
                .frame(width: 14 * hairWidthScale, height: 34)
                .offset(x: -40 * hairWidthScale, y: -10)

            TempleWispShape(isLeft: false)
                .fill(color)
                .frame(width: 14 * hairWidthScale, height: 34)
                .offset(x: 40 * hairWidthScale, y: -10)
        }
    }

    private func bunTop(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
                .offset(x: 18, y: -64)

            Capsule()
                .fill(.black.opacity(0.10))
                .frame(width: 18, height: 4)
                .offset(x: 18, y: -56)
        }
    }

    private func centrePartHighlight() -> some View {
        Capsule()
            .fill(.black.opacity(0.08))
            .frame(width: 10, height: 28)
            .offset(y: -22)
    }

    // MARK: Front locks

    private enum FrontLockStyle { case shoulder, longStraight, longWavy, longCurls }

    private func frontLocks(style: FrontLockStyle, color: Color) -> some View {
        let (w, h, x, y, flare, wave): (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) = {
            switch style {
            case .shoulder:     return (28, 56, 38, -6, 0.22, 0.00)
            case .longStraight: return (22, 78, 40, -2, 0.12, 0.00)
            case .longWavy:     return (24, 80, 40, -2, 0.14, 0.10)
            case .longCurls:    return (26, 82, 40,  0, 0.16, 0.16)
            }
        }()

        return ZStack {
            TaperedLockShape(isLeft: true, flare: flare, wave: wave)
                .fill(color)
                .frame(width: w * hairWidthScale, height: h)
                .offset(x: -x * hairWidthScale, y: y)

            TaperedLockShape(isLeft: false, flare: flare, wave: wave)
                .fill(color)
                .frame(width: w * hairWidthScale, height: h)
                .offset(x: x * hairWidthScale, y: y)
        }
        // Subtract a face-shaped clear zone so hair NEVER covers the face.
        .overlay(
            faceShape
                .fill(.black)
                .frame(width: 102 * hairWidthScale, height: 114)
                .offset(y: -4)
                .blendMode(.destinationOut)
        )
        .compositingGroup()
    }

    // MARK: Hair helper shapes

    private struct BackSkullShape: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.addEllipse(in: rect)
            return p
        }
    }

    private struct ShortCrownShape: Shape, Sendable {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            let left = rect.minX
            let right = rect.maxX
            let top = rect.minY
            let midX = rect.midX
            let hairlineY = rect.minY + h * 0.56

            var p = Path()
            p.move(to: CGPoint(x: left + w * 0.10, y: hairlineY))
            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.10, y: hairlineY),
                control: CGPoint(x: midX, y: hairlineY - h * 0.18)
            )

            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.14, y: top + h * 0.14),
                control: CGPoint(x: right, y: top + h * 0.34)
            )

            p.addQuadCurve(
                to: CGPoint(x: left + w * 0.14, y: top + h * 0.14),
                control: CGPoint(x: midX, y: top - h * 0.06)
            )

            p.addQuadCurve(
                to: CGPoint(x: left + w * 0.10, y: hairlineY),
                control: CGPoint(x: left, y: top + h * 0.34)
            )

            p.closeSubpath()
            return p
        }
    }

    private struct SweptBackCrownShape: Shape, Sendable {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            let left = rect.minX
            let right = rect.maxX
            let top = rect.minY
            let midX = rect.midX

            let hairlineY = rect.minY + h * 0.62

            var p = Path()
            p.move(to: CGPoint(x: left + w * 0.14, y: hairlineY))

            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.14, y: hairlineY),
                control: CGPoint(x: midX, y: hairlineY - h * 0.22)
            )

            p.addQuadCurve(
                to: CGPoint(x: right - w * 0.18, y: top + h * 0.14),
                control: CGPoint(x: right, y: top + h * 0.40)
            )
            p.addQuadCurve(
                to: CGPoint(x: left + w * 0.18, y: top + h * 0.14),
                control: CGPoint(x: midX - w * 0.10, y: top - h * 0.10)
            )
            p.addQuadCurve(
                to: CGPoint(x: left + w * 0.14, y: hairlineY),
                control: CGPoint(x: left, y: top + h * 0.40)
            )

            p.closeSubpath()
            return p
        }
    }

    private struct SoftFringeShape: Shape, Sendable {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            let top = rect.minY
            let bottom = rect.maxY
            let left = rect.minX
            let right = rect.maxX
            let midX = rect.midX

            var p = Path()
            p.move(to: CGPoint(x: left, y: top + h * 0.30))
            p.addQuadCurve(to: CGPoint(x: midX, y: top + h * 0.12),
                           control: CGPoint(x: midX - w * 0.18, y: top + h * 0.04))
            p.addQuadCurve(to: CGPoint(x: right, y: top + h * 0.30),
                           control: CGPoint(x: midX + w * 0.18, y: top + h * 0.04))
            p.addLine(to: CGPoint(x: right, y: bottom))
            p.addQuadCurve(to: CGPoint(x: left, y: bottom),
                           control: CGPoint(x: midX, y: bottom + h * 0.20))
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
                case .shoulder:     return (top + h * 0.74, h * 0.06, 0.02, 0.00)
                case .tiedBack:     return (top + h * 0.70, h * 0.08, 0.00, 0.00)
                case .longStraight: return (top + h * 0.84, h * 0.02, 0.00, 0.00)
                case .longWavy:     return (top + h * 0.86, h * 0.02, 0.10, 0.00)
                case .longCurls:    return (top + h * 0.88, h * 0.00, 0.12, 0.20)
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

    private struct TaperedLockShape: Shape, Sendable {
        let isLeft: Bool
        let flare: CGFloat
        let wave: CGFloat

        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height

            let outerX = isLeft ? rect.minX : rect.maxX
            let innerX = isLeft ? rect.maxX : rect.minX

            let top = rect.minY
            let bottom = rect.maxY

            let topInner = CGPoint(x: innerX, y: top + h * 0.10)
            let topOuter = CGPoint(x: outerX, y: top + h * 0.22)

            let bulge = w * (0.22 + flare)
            let waveAmt = h * wave

            var p = Path()
            p.move(to: topInner)

            p.addQuadCurve(
                to: topOuter,
                control: CGPoint(
                    x: (topInner.x + topOuter.x) * 0.5,
                    y: top - h * 0.04
                )
            )

            p.addCurve(
                to: CGPoint(x: outerX + (isLeft ? -bulge * 0.25 : bulge * 0.25), y: bottom - h * 0.12),
                control1: CGPoint(x: outerX + (isLeft ? -bulge : bulge), y: top + h * 0.42 + waveAmt),
                control2: CGPoint(x: outerX + (isLeft ? -bulge * 0.70 : bulge * 0.70), y: top + h * 0.72 - waveAmt)
            )

            p.addQuadCurve(
                to: CGPoint(x: innerX, y: bottom),
                control: CGPoint(x: rect.midX, y: bottom + h * 0.10)
            )

            p.addQuadCurve(
                to: topInner,
                control: CGPoint(
                    x: innerX + (isLeft ? -w * 0.18 : w * 0.18),
                    y: top + h * 0.56
                )
            )

            p.closeSubpath()
            return p
        }
    }

    private struct TempleWispShape: Shape, Sendable {
        let isLeft: Bool

        func path(in rect: CGRect) -> Path {
            let h = rect.height

            let outerX = isLeft ? rect.minX : rect.maxX
            let innerX = isLeft ? rect.maxX : rect.minX

            var p = Path()
            p.move(to: CGPoint(x: innerX, y: rect.minY + h * 0.10))
            p.addQuadCurve(
                to: CGPoint(x: outerX, y: rect.minY + h * 0.28),
                control: CGPoint(x: rect.midX, y: rect.minY - h * 0.06)
            )
            p.addQuadCurve(
                to: CGPoint(x: innerX, y: rect.maxY),
                control: CGPoint(x: rect.midX, y: rect.minY + h * 0.80)
            )
            p.addLine(to: CGPoint(x: innerX, y: rect.minY + h * 0.10))
            p.closeSubpath()
            return p
        }
    }

    private struct WavyHighlightShape: Shape, Sendable {
        let isLeft: Bool

        func path(in rect: CGRect) -> Path {
            let h = rect.height
            let x0 = isLeft ? rect.maxX : rect.minX
            let x1 = isLeft ? rect.minX : rect.maxX

            var p = Path()
            p.move(to: CGPoint(x: x0, y: rect.minY))
            p.addCurve(
                to: CGPoint(x: x1, y: rect.minY + h * 0.33),
                control1: CGPoint(x: x0, y: rect.minY + h * 0.10),
                control2: CGPoint(x: x1, y: rect.minY + h * 0.16)
            )
            p.addCurve(
                to: CGPoint(x: x0, y: rect.minY + h * 0.66),
                control1: CGPoint(x: x1, y: rect.minY + h * 0.50),
                control2: CGPoint(x: x0, y: rect.minY + h * 0.54)
            )
            p.addCurve(
                to: CGPoint(x: x1, y: rect.maxY),
                control1: CGPoint(x: x0, y: rect.minY + h * 0.80),
                control2: CGPoint(x: x1, y: rect.minY + h * 0.86)
            )
            p.addLine(to: CGPoint(x: x0, y: rect.maxY))
            p.closeSubpath()
            return p
        }
    }

    private struct CurlClusterShape: Shape {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height

            var p = Path()
            p.addEllipse(in: CGRect(x: w * 0.05, y: h * 0.05, width: w * 0.45, height: w * 0.45))
            p.addEllipse(in: CGRect(x: w * 0.42, y: h * 0.10, width: w * 0.52, height: w * 0.52))
            p.addEllipse(in: CGRect(x: w * 0.10, y: h * 0.42, width: w * 0.54, height: w * 0.54))
            p.addEllipse(in: CGRect(x: w * 0.46, y: h * 0.48, width: w * 0.50, height: w * 0.50))
            p.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.72, width: w * 0.58, height: w * 0.58))
            return p
        }
    }

    private struct PonytailShape: Shape {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height

            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addCurve(
                to: CGPoint(x: rect.midX, y: rect.maxY),
                control1: CGPoint(x: rect.midX + w * 0.90, y: rect.minY + h * 0.25),
                control2: CGPoint(x: rect.midX - w * 0.90, y: rect.minY + h * 0.72)
            )
            p.addQuadCurve(
                to: CGPoint(x: rect.midX, y: rect.minY),
                control: CGPoint(x: rect.midX + w * 0.45, y: rect.minY + h * 0.18)
            )
            p.closeSubpath()
            return p
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
        case .round, .roundThin:   return AnyView(roundFrame())
        case .square, .squareThin: return AnyView(squareFrame())
        case .hex:                 return AnyView(hexFrame())
        }
    }

    // MARK: Hats

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

// MARK: - Helpers (shared)

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

