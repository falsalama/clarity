import SwiftUI

/// 27-bead mala ring with centre portrait.
/// - Filled beads start at 12 o'clock.
/// - Empty: ghost outline.
/// - Complete: warm charcoal “wood” bead.
/// - Partial: gold fill for in-progress daily state.
/// - Includes a minimal guru bead + collar + tassel.
struct Mala27View: View {
    let openCount: Int
    let didWisdomToday: Bool
    let didCompassionToday: Bool
    let overlayPartialOnLastOpenBead: Bool
    let layersCompleted: Int
    let portraitRecipe: PortraitRecipe
    let pulseCentre: Bool
    let onPortraitTap: () -> Void

    private let beadCount = 27
    @State private var isPulsing = false

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            let ringRadius = size * 0.41
            let circumference = 2.0 * Double.pi * Double(ringRadius)
            let step = circumference / Double(beadCount)
            let bead = min(size * 0.090, CGFloat(step) * 1.08)

            let ghostStroke = Color.primary.opacity(0.10)
            let fill = Color(red: 0.14, green: 0.13, blue: 0.12)

            let fullCount = min(max(openCount, 0), beadCount)
            let hasPartial = didWisdomToday || didCompassionToday

            let angleOffset = -Double.pi / 2.0

            ZStack {
                GuruBeadView(
                    centre: CGPoint(x: size * 0.5, y: size * 0.5 - ringRadius),
                    bead: bead,
                    fill: fill,
                    ghostStroke: ghostStroke
                )

                ForEach(0..<beadCount, id: \.self) { i in
                    let angle = (Double(i) / Double(beadCount)) * 2.0 * Double.pi + angleOffset
                    let isOpen = i < fullCount
                    let partialIndex = overlayPartialOnLastOpenBead
                        ? max(0, min(fullCount - 1, beadCount - 1))
                        : min(fullCount, beadCount - 1)

                    let isPartialSlot = hasPartial && i == partialIndex

                    if !isPartialSlot {
                        ZStack {
                            Circle()
                                .stroke(ghostStroke, lineWidth: 2.2)

                            if isOpen {
                                Circle()
                                    .fill(fill)
                                    .shadow(
                                        color: .black.opacity(0.22),
                                        radius: 2.4,
                                        x: 0,
                                        y: 1.7
                                    )

                                Circle()
                                    .fill(Color.white.opacity(0.10))
                                    .blur(radius: 0.6)
                                    .offset(x: -0.6, y: -0.9)
                                    .mask(Circle())
                            }
                        }
                        .frame(width: bead, height: bead)
                        .position(
                            x: size * 0.5 + cos(angle) * ringRadius,
                            y: size * 0.5 + sin(angle) * ringRadius
                        )
                        .animation(.easeOut(duration: 1.2), value: openCount)
                    }
                }

                if hasPartial {
                    let partialIndex = overlayPartialOnLastOpenBead
                        ? max(0, min(fullCount - 1, beadCount - 1))
                        : min(fullCount, beadCount - 1)

                    let partialAngle = (Double(partialIndex) / Double(beadCount)) * 2.0 * Double.pi + angleOffset

                    ZStack {
                        Circle()
                            .stroke(ghostStroke, lineWidth: 2.2)

                        PartialBeadFillView(
                            didWisdomToday: didWisdomToday,
                            didCompassionToday: didCompassionToday,
                            rotationDegrees: partialAngle * 180.0 / .pi,
                            showsBackgroundBase: !overlayPartialOnLastOpenBead
                        )
                    }
                    .frame(width: bead, height: bead)
                    .position(
                        x: size * 0.5 + cos(partialAngle) * ringRadius,
                        y: size * 0.5 + sin(partialAngle) * ringRadius
                    )
                    .zIndex(100)
                    .animation(.easeOut(duration: 0.6), value: "\(didWisdomToday)-\(didCompassionToday)")
                }

                ZStack {
                    if pulseCentre {
                        Circle()
                            .stroke(Color.primary.opacity(0.18), lineWidth: 8)
                            .scaleEffect(isPulsing ? 1.16 : 1.02)
                            .opacity(isPulsing ? 0.0 : 1.0)
                            .animation(.easeInOut(duration: 0.55).repeatCount(2, autoreverses: false), value: isPulsing)
                    }

                    Button(action: onPortraitTap) {
                        PortraitView(recipe: portraitRecipe)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: size * 0.42, height: size * 0.42)
            }
            .frame(width: size, height: size)
            .onAppear {
                guard pulseCentre else { return }
                isPulsing = false
                DispatchQueue.main.async { isPulsing = true }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.vertical, 12)
    }
}

private struct PartialBeadFillView: View {
    let didWisdomToday: Bool
    let didCompassionToday: Bool
    let rotationDegrees: Double
    let showsBackgroundBase: Bool

    private let gold = Color(red: 0.86, green: 0.72, blue: 0.22)
    private let claret = Color(red: 0.48, green: 0.18, blue: 0.22)
    private let wood = Color(red: 0.14, green: 0.13, blue: 0.12)

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let activeStroke: Color = didCompassionToday ? claret : (didWisdomToday ? gold : wood)
            let third = size / 3.0

            ZStack {
                if showsBackgroundBase {
                    Circle()
                        .fill(Color(.systemBackground))

                    Circle()
                        .fill(activeStroke.opacity(0.04))
                } else {
                    Circle()
                        .fill(wood)
                        .shadow(
                            color: .black.opacity(0.22),
                            radius: 2.4,
                            x: 0,
                            y: 1.7
                        )

                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .blur(radius: 0.6)
                        .offset(x: -0.6, y: -0.9)
                        .mask(Circle())
                }

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(didWisdomToday ? gold : .clear)
                        .frame(width: third)

                    Rectangle()
                        .fill(didCompassionToday ? claret : .clear)
                        .frame(width: third)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: third)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                .rotationEffect(.degrees(rotationDegrees))

                Circle()
                    .stroke(activeStroke.opacity(0.55), lineWidth: 1.2)
            }
            .shadow(
                color: activeStroke.opacity(0.18),
                radius: 1.8,
                x: 0,
                y: 1.1
            )
        }
    }
}
private struct GuruBeadView: View {
    let centre: CGPoint
    let bead: CGFloat
    let fill: Color
    let ghostStroke: Color

    var body: some View {
        let cord = Color.black.opacity(0.22)
        let cordShadow = Color.black.opacity(0.12)

        let guruH = bead * 1.75
        let guruW = bead * 0.95

        let cordDX = bead * 0.18
        let rise = bead * 1.05
        let stop = bead * 0.34

        let guruCentre = CGPoint(x: centre.x, y: centre.y)
        let collarY = guruCentre.y - guruH * 0.62
        let knotCentre = CGPoint(x: centre.x, y: collarY - bead * 0.40)
        let endY = knotCentre.y - rise

        let loopW = bead * 0.78
        let loopH = bead * 0.52

        ZStack {
            Path { p in
                let startL = CGPoint(x: knotCentre.x - cordDX, y: knotCentre.y)
                let endL   = CGPoint(x: startL.x, y: endY)

                let startR = CGPoint(x: knotCentre.x + cordDX, y: knotCentre.y)
                let endR   = CGPoint(x: startR.x, y: endY)

                p.move(to: startL)
                p.addCurve(
                    to: endL,
                    control1: CGPoint(x: startL.x - bead * 0.06, y: startL.y - bead * 0.22),
                    control2: CGPoint(x: endL.x + bead * 0.05, y: endL.y + bead * 0.18)
                )

                p.move(to: startR)
                p.addCurve(
                    to: endR,
                    control1: CGPoint(x: startR.x + bead * 0.06, y: startR.y - bead * 0.22),
                    control2: CGPoint(x: endR.x - bead * 0.05, y: endR.y + bead * 0.18)
                )
            }
            .stroke(cord, style: StrokeStyle(lineWidth: 4.6, lineCap: .round))
            .shadow(color: cordShadow, radius: 1.2, x: 0, y: 0.8)

            Circle()
                .fill(fill.opacity(0.85))
                .overlay(Circle().stroke(ghostStroke, lineWidth: 1.2))
                .frame(width: stop, height: stop)
                .position(x: knotCentre.x - cordDX, y: endY)

            Circle()
                .fill(fill.opacity(0.85))
                .overlay(Circle().stroke(ghostStroke, lineWidth: 1.2))
                .frame(width: stop, height: stop)
                .position(x: knotCentre.x + cordDX, y: endY)

            ZStack {
                RoundedRectangle(cornerRadius: loopH * 0.45, style: .continuous)
                    .stroke(cord, lineWidth: 4.2)
                    .frame(width: loopW, height: loopH)

                RoundedRectangle(cornerRadius: loopH * 0.45, style: .continuous)
                    .stroke(cord, lineWidth: 4.2)
                    .frame(width: loopW, height: loopH)
                    .rotationEffect(.degrees(90))

                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(width: 6, height: loopH * 0.55)

                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(width: loopW * 0.55, height: 6)
            }
            .shadow(color: cordShadow, radius: 1.0, x: 0, y: 0.8)
            .position(knotCentre)

            RoundedRectangle(cornerRadius: guruH * 0.26, style: .continuous)
                .fill(fill.opacity(0.98))
                .frame(width: guruW, height: guruH)
                .shadow(color: .black.opacity(0.18), radius: 2.0, x: 0, y: 1.6)
                .overlay(
                    RoundedRectangle(cornerRadius: guruH * 0.26, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        .blur(radius: 0.2)
                        .offset(y: -0.6)
                )
                .position(guruCentre)

            Circle()
                .fill(fill.opacity(0.60))
                .overlay(Circle().stroke(ghostStroke, lineWidth: 1.4))
                .frame(width: bead * 0.56, height: bead * 0.56)
                .position(x: guruCentre.x, y: collarY)
        }
    }
}

/// Tibetan “male abacus” style layer counter (horizontal).
struct QuarterMalaCountersView: View {
    let rounds: Int

    var body: some View {
        let v = max(0, min(rounds, 27))
        let top = min(v, 9)
        let middle = min(max(v - 9, 0), 9)
        let bottom = min(max(v - 18, 0), 9)

        VStack(spacing: 10) {
            row(filled: top)
            row(filled: middle)
            row(filled: bottom)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Quarter mala counters")
        .accessibilityValue("\(v) rounds")
    }

    private func row(filled: Int) -> some View {
        let ghost = Color.primary.opacity(0.12)
        let cord = Color.primary.opacity(0.16)
        let fill = Color(red: 0.14, green: 0.13, blue: 0.12)

        return ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(cord)
                .frame(height: 5)

            HStack {
                Circle()
                    .fill(fill.opacity(0.92))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    .frame(width: 9, height: 9)

                Spacer()

                Circle()
                    .fill(fill.opacity(0.92))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    .frame(width: 9, height: 9)
            }
            .padding(.horizontal, 2)

            HStack(spacing: 8) {
                ForEach(0..<9, id: \.self) { i in
                    let on = i < filled

                    ZStack {
                        Circle()
                            .fill(on ? fill : Color.clear)

                        Circle()
                            .stroke(on ? Color.clear : ghost, lineWidth: 1.8)

                        Circle()
                            .fill(Color.white.opacity(on ? 0.14 : 0.0))
                            .frame(width: 7, height: 7)
                            .offset(x: -2, y: -2)
                    }
                    .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 18)

            HStack {
                knotView
                Spacer()
                knotView
            }
            .padding(.horizontal, 10)
        }
        .frame(width: 220, height: 34)
    }

    private var knotView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1.6)
                .frame(width: 7, height: 7)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1.6)
                .frame(width: 7, height: 7)
                .rotationEffect(.degrees(45))
        }
    }
}
