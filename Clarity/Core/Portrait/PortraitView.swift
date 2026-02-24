import SwiftUI

struct PortraitView: View {

    let recipe: PortraitRecipe
    private let globalRotation: Double = 0.7

    var body: some View {
        ZStack {
            ZStack {
                Image("PORTRAIT")
                    .resizable()
                    .scaledToFit()

                let robe = recipe.robe ?? .lay
                Image(robe.rawValue)
                    .resizable()
                    .scaledToFit()

                if robe == .western {
                    Image("shirt")
                        .resizable()
                        .scaledToFit()
                }

                if let hair = recipe.hair {
                    Image(hair.rawValue)
                        .resizable()
                        .scaledToFit()
                }

                if let glasses = recipe.glasses {
                    Image(glasses.rawValue)
                        .resizable()
                        .scaledToFit()
                }
            }
            .rotationEffect(.degrees(globalRotation))
            .clipShape(Circle())
        }
        // MARK: - CHANGED: halo moved to background so it does not affect layout sizing (hub-safe)
        .background {
            if let halo = recipe.halo {
                haloView(halo)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }

    // MARK: - Halo

    private func haloView(_ halo: HaloID) -> some View {
        let design: CGFloat = 140 // MARK: - CHANGED: author in design-space, then scale to container

        switch halo {

        case .golden:
            // MARK: - CHANGED: single band + larger padding + scaled
            return AnyView(
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let scale = side / design

                    Circle()
                        .stroke(haloStroke(halo), lineWidth: 10) // MARK: - CHANGED
                        .opacity(0.70)                            // MARK: - CHANGED
                        .blur(radius: 0.6)
                        .padding(6)                               // MARK: - CHANGED
                        .frame(width: design, height: design)     // MARK: - CHANGED
                        .scaleEffect(scale, anchor: .center)      // MARK: - CHANGED
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .allowsHitTesting(false)
                }
                .aspectRatio(1, contentMode: .fit)
            )

        case .silver:
            // MARK: - CHANGED: single band + larger padding + scaled
            return AnyView(
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let scale = side / design

                    Circle()
                        .stroke(haloStroke(halo), lineWidth: 10) // MARK: - CHANGED
                        .opacity(0.70)                            // MARK: - CHANGED
                        .blur(radius: 0.6)
                        .padding(6)                               // MARK: - CHANGED
                        .frame(width: design, height: design)     // MARK: - CHANGED
                        .scaleEffect(scale, anchor: .center)      // MARK: - CHANGED
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .allowsHitTesting(false)
                }
                .aspectRatio(1, contentMode: .fit)
            )

        case .rainbow:
            // Concentric banded rings (full circles)
            let bands: [(Color, CGFloat)] = [
                (.red,    5),
                (.orange, 5),
                (.yellow, 5),
                (.green,  5),
                (.cyan,   5),
                (.blue,   5),
            ]

            let spacing: CGFloat = 1.5

            // MARK: - CHANGED: scaled so fixed stroke/blur sizes don't dominate in hub
            return AnyView(
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let scale = side / design

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.10), lineWidth: 22)
                            .blur(radius: 10)
                            .opacity(0.25)

                        ForEach(Array(bands.enumerated()), id: \.offset) { idx, band in
                            let (c, w) = band
                            let inset = CGFloat(idx) * (w + spacing)

                            Circle()
                                .stroke(c.opacity(0.80), lineWidth: w)
                                .padding(inset)
                                .blur(radius: 0.6)
                        }
                    }
                    .padding(6)
                    .frame(width: design, height: design)     // MARK: - CHANGED
                    .scaleEffect(scale, anchor: .center)      // MARK: - CHANGED
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .allowsHitTesting(false)
                }
                .aspectRatio(1, contentMode: .fit)
            )
        }
    }

    private func haloStroke(_ halo: HaloID) -> AnyShapeStyle {
        switch halo {
        case .golden:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.84, blue: 0.36),
                        Color(red: 0.86, green: 0.56, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

        case .silver:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.92, blue: 0.94),
                        Color(red: 0.62, green: 0.66, blue: 0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

        case .rainbow:
            // Not used (rainbow is banded rings), but keep for completeness.
            return AnyShapeStyle(Color.white)
        }
    }
}
