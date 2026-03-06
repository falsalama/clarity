import SwiftUI

struct FocusSoundsHubView: View {
    private let soundPlaceholders: [SoundPlaceholder] = [
        .init(title: "Bell", subtitle: "Short settling tone", duration: "20 sec", gradient: [.orange.opacity(0.22), .yellow.opacity(0.12)]),
        .init(title: "Wind", subtitle: "Light ambient field", duration: "30 sec", gradient: [.cyan.opacity(0.20), .blue.opacity(0.10)]),
        .init(title: "Resonance", subtitle: "Held meditative texture", duration: "40 sec", gradient: [.purple.opacity(0.20), .indigo.opacity(0.10)]),
        .init(title: "Field", subtitle: "Natural recorded space", duration: "45 sec", gradient: [.green.opacity(0.20), .mint.opacity(0.10)]),
        .init(title: "Drone", subtitle: "Longer grounding bed", duration: "60 sec", gradient: [.indigo.opacity(0.22), .blue.opacity(0.12)])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Sounds")
                        .font(.headline)

                    ForEach(soundPlaceholders) { item in
                        SoundPlaceholderCard(item: item)
                    }
                }

                futureCard
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.06),
                    Color.clear,
                    Color.orange.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Focus")
                        .font(.headline)

                    Text("Meditative sounds")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meditative sounds")
                .font(.title3.weight(.semibold))

            Text("A small collection of carefully made sound for practice, settling, and rest. This is a quiet support space - not a content library.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    private var futureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Later")
                .font(.headline)

            Text("Sleep and longer listening can live here later without changing the overall structure.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

private struct SoundPlaceholder: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let duration: String
    let gradient: [Color]
}

private struct SoundPlaceholderCard: View {
    let item: SoundPlaceholder

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 62, height: 62)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundStyle(.primary.opacity(0.75))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(item.duration)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}
