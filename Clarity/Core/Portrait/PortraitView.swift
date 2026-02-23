import SwiftUI

struct PortraitView: View {

    let recipe: PortraitRecipe
    private let globalRotation: Double = 0.5

    var body: some View {
        ZStack {
            if let halo = recipe.halo {
                haloView(halo)
            }

            ZStack {
                Image("PORTRAIT")
                    .resizable()
                    .scaledToFit()

                if let robe = recipe.robe {
                    Image(robe.rawValue)
                        .resizable()
                        .scaledToFit()

                    if robe == .western {
                        Image("shirt")
                            .resizable()
                            .scaledToFit()
                    }
                }

                if let hair = recipe.hair {
                    Image(hair.rawValue)
                        .resizable()
                        .scaledToFit()
                }
            }
            .rotationEffect(.degrees(globalRotation))
            .clipShape(Circle())
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Halo

    private func haloView(_ halo: HaloID) -> some View {
        switch halo {
        case .golden, .silver:
            let bands: [(CGFloat, CGFloat)] = [
                (8, 0.55),  // (lineWidth, opacity)
                (8, 0.55),
                (8, 0.55),
            ]
            let spacing: CGFloat = 1.5

            return AnyView(
                ZStack {
                    ForEach(Array(bands.enumerated()), id: \.offset) { idx, spec in
                        let (w, o) = spec
                        let inset = CGFloat(idx) * (w + spacing)

                        Circle()
                            .stroke(haloStroke(halo), lineWidth: w)
                            .opacity(o)
                            .padding(inset)
                            .blur(radius: 0.6) // tiny, survives in 28x28
                    }
                }
                .padding(2) // small so it doesn’t get pushed out of bounds
                .allowsHitTesting(false)
            )

        case .rainbow:
            // Concentric banded rings (full circles)
            let bands: [(Color, CGFloat)] = [
                (.red,    6),
                (.orange, 6),
                (.yellow, 6),
                (.green,  6),
                (.cyan,   6),
                (.blue,   6),
                (.purple, 6),
            ]

            let spacing: CGFloat = 1.5

            return AnyView(
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
                .allowsHitTesting(false)
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
