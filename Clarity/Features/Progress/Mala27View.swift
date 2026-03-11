// Clarity/Features/Progress/Mala27View.swift

import SwiftUI

/// 27-bead mala ring with centre portrait.
/// - Filled beads start at 12 o'clock.
/// - Empty: ghost outline.
/// - Complete: warm charcoal “wood” bead.
/// - Includes a minimal guru bead + collar + tassel.
/// - Exposes `layersCompleted` for external UI (layer counters live in ProgressView).
struct Mala27View: View {
    let openCount: Int
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

            // 12 o'clock start
            let angleOffset = -Double.pi / 2.0

            ZStack {
                // Guru bead + tassel at 12 o'clock (not counted)
                GuruBeadView(
                    centre: CGPoint(x: size * 0.5, y: size * 0.5 - ringRadius),
                    bead: bead,
                    fill: fill,
                    ghostStroke: ghostStroke
                )

                ForEach(0..<beadCount, id: \.self) { i in
                    let angle = (Double(i) / Double(beadCount)) * 2.0 * Double.pi + angleOffset
                    let isOpen = i < min(max(openCount, 0), beadCount)

                    ZStack {
                        Circle()
                            .stroke(ghostStroke, lineWidth: 2.2)

                        Circle()
                            .fill(fill)
                            .opacity(isOpen ? 1 : 0)
                            .scaleEffect(isOpen ? 1 : 0.7)
                            .shadow(
                                color: .black.opacity(isOpen ? 0.22 : 0.0),
                                radius: isOpen ? 2.4 : 0,
                                x: 0,
                                y: isOpen ? 1.7 : 0
                            )

                        Circle()
                            .fill(Color.white.opacity(isOpen ? 0.10 : 0.0))
                            .blur(radius: 0.6)
                            .offset(x: -0.6, y: -0.9)
                            .mask(Circle())
                    }
                    .frame(width: bead, height: bead)
                    .position(
                        x: size * 0.5 + cos(angle) * ringRadius,
                        y: size * 0.5 + sin(angle) * ringRadius
                    )
                    .animation(.easeOut(duration: 1.2), value: openCount)
                }

                // Centre portrait + optional pulse halo
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

        // Spacing controls
        let cordDX = bead * 0.18
        let rise = bead * 1.05        // how far the strands go upward
        let stop = bead * 0.34

        // Core anchors
        let guruCentre = CGPoint(x: centre.x, y: centre.y)

        // Collar bead above the guru bead
        let collarY = guruCentre.y - guruH * 0.62

        // Knot sits just ABOVE the collar bead (close to the mala)
        let knotCentre = CGPoint(x: centre.x, y: collarY - bead * 0.40)

        // Cord ends (stopper beads) above the knot
        let endY = knotCentre.y - rise

        // Knot sizing
        let loopW = bead * 0.78
        let loopH = bead * 0.52

        ZStack {
            // Cords start at knot and go UP
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

            // Stopper beads at cord ends
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

            // Knot loop (NOW near the mala / collar)
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

            // Guru bead body
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

            // Collar bead (between guru bead and knot)
            Circle()
                .fill(fill.opacity(0.60))
                .overlay(Circle().stroke(ghostStroke, lineWidth: 1.4))
                .frame(width: bead * 0.56, height: bead * 0.56)
                .position(x: guruCentre.x, y: collarY)
        }
    }
}

/// Tibetan “male abacus” style layer counter (horizontal).
/// - Shows up to 20 layers as two rows of 10.
/// - Row 1 fills 0...10, then Row 2 fills 0...10.
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
            // cord
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(cord)
                .frame(height: 5)

            // end stopper beads
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

            // beads
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

            // little knots just inside the stopper beads
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
