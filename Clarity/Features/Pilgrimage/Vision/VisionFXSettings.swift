import SwiftUI
import CoreLocation

// MARK: - FX Settings (persisted)

struct VisionFXSettings: Equatable {
    var edgeDissolve: Bool = false
    var dependencyLines: Bool = true
    var nameFade: Bool = true
    var timeTrail: Bool = false
    var spaceSparkles: Bool = true
}

enum VisionFXKey {
    static let edgeDissolve = "visionfx.edgeDissolve"
    static let dependencyLines = "visionfx.dependencyLines"
    static let nameFade = "visionfx.nameFade"
    static let timeTrail = "visionfx.timeTrail"
    static let spaceSparkles = "visionfx.spaceSparkles"
}

struct VisionFXPanel: View {
    @AppStorage(VisionFXKey.edgeDissolve) private var edgeDissolve = false
    @AppStorage(VisionFXKey.dependencyLines) private var dependencyLines = true
    @AppStorage(VisionFXKey.nameFade) private var nameFade = true
    @AppStorage(VisionFXKey.timeTrail) private var timeTrail = false
    @AppStorage(VisionFXKey.spaceSparkles) private var spaceSparkles = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Vision FX (optional)") {
                    Toggle("Edge dissolve", isOn: $edgeDissolve)
                    Toggle("Dependency lines", isOn: $dependencyLines)
                    Toggle("Name fade", isOn: $nameFade)
                    Toggle("Time trail", isOn: $timeTrail)
                    Toggle("Space sparkles", isOn: $spaceSparkles)
                }

                Section {
                    Text("UI overlays only. No AR anchors or camera filtering yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Vision FX")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Overlay renderer

struct VisionFXOverlay: View {
    let placeName: String?
    let distanceMeters: Double?
    let showCloseGate: Bool
    let isCloseEnough: Bool

    @AppStorage(VisionFXKey.edgeDissolve) private var edgeDissolve = false
    @AppStorage(VisionFXKey.dependencyLines) private var dependencyLines = true
    @AppStorage(VisionFXKey.nameFade) private var nameFade = true
    @AppStorage(VisionFXKey.timeTrail) private var timeTrail = false
    @AppStorage(VisionFXKey.spaceSparkles) private var spaceSparkles = true

    @State private var nameOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // subtle background sparkles (only when inside radius)
            if isCloseEnough, spaceSparkles {
                SpaceSparklesView()
                    .allowsHitTesting(false)
            }

            // Top-left label (kept clear; VisionView has its own HUD top)
            if let placeName {
                placeLabel(placeName: placeName, distanceMeters: distanceMeters)
                    .allowsHitTesting(false)
                    .padding(.top, 64)      // push below nav bar / HUD
                    .padding(.leading, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Close-gate message (top, centred, below HUD)
            if showCloseGate, !isCloseEnough {
                closeGateOverlay
                    .allowsHitTesting(false)
                    .padding(.top, 118)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            // Bottom-left dependency box (kept above safeAreaInset bottom card)
            if isCloseEnough, dependencyLines, let placeName {
                DependencyLinesOverlay(subject: placeName)
                    .allowsHitTesting(false)
                    .padding(.leading, 12)
                    .padding(.bottom, 120)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }

            // Small “hint chips” (stacked under the HUD zone, not centre-screen)
            if isCloseEnough, edgeDissolve {
                HintChip(text: "edges soften - nothing is fixed")
                    .padding(.top, 122)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)
            }

            if isCloseEnough, timeTrail {
                HintChip(text: "time is layered - form is transient")
                    .padding(.top, 166)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)
            }
        }
        .onAppear { applyNameFade() }
        .onChange(of: nameFade) { _, _ in applyNameFade() }
    }

    private func applyNameFade() {
        nameOpacity = 1.0
        guard nameFade else { return }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            nameOpacity = 0.35
        }
    }

    private var closeGateOverlay: some View {
        VStack(spacing: 6) {
            Text("Move closer to activate Vision")
                .font(.headline)
            if let d = distanceMeters {
                Text("\(Int(d.rounded())) m away")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Location needed (tap Find nearby in Pilgrimage).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func placeLabel(placeName: String, distanceMeters: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            if let distanceMeters {
                Text(distanceString(distanceMeters))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(nameOpacity)
    }

    private func distanceString(_ meters: Double) -> String {
        if meters < 1000 { return "\(Int(meters.rounded())) m" }
        return String(format: "%.1f km", meters / 1000.0)
    }
}

// MARK: - Components

private struct HintChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.thinMaterial, in: Capsule())
    }
}

private struct DependencyLinesOverlay: View {
    let subject: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("dependently arisen")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(subject)
                    .font(.footnote.weight(.semibold))
                Text("↘ light")
                Text("↘ weather")
                Text("↘ history")
                Text("↘ attention")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SpaceSparklesView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // Make them actually visible (still subtle)
                let count = 42
                for i in 0..<count {
                    let seed = Double(i) * 97.321
                    let x = (sin(t * 0.18 + seed) * 0.48 + 0.5) * size.width
                    let y = (cos(t * 0.14 + seed * 1.2) * 0.48 + 0.5) * size.height
                    let r = CGFloat((sin(t * 0.7 + seed) * 0.7 + 1.2) * 1.4)

                    var path = Path()
                    path.addEllipse(in: CGRect(x: x, y: y, width: r, height: r))
                    context.fill(path, with: .color(Color.white.opacity(0.14)))
                }
            }
        }
    }
}

private struct EdgeDissolveHintOverlay: View {
    var body: some View {
        Text("edges soften - nothing is fixed")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 72)
    }
}

private struct TimeTrailHintOverlay: View {
    var body: some View {
        Text("time is layered - form is transient")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 112)
    }
}
