import SwiftUI

struct FocusSoundsHubView: View {
    @ObservedObject private var player = FocusAudioPlayer.shared
    
    private let sounds: [FocusSoundItem] = [
        .init(
            title: "Crystal 1",
            subtitle: "settling spacious tones",
            fileName: "focus-crystal cave-1",
            durationLabel: "1m 38s",
            tint: Color(red: 0.78, green: 0.58, blue: 0.10) // saffron
        ),
        .init(
            title: "Crystal 2",
            subtitle: "Clear resonant pace",
            fileName: "focus-crystal shell-2",
            durationLabel: "1m 29s",
            tint: Color(red: 0.55, green: 0.10, blue: 0.14) // maroon
        ),
        .init(
            title: "Crystal 3",
            subtitle: "Held meditative shimmer",
            fileName: "focus-crystal chant-3",
            durationLabel: "1m 29s",
            tint: Color(red: 0.16, green: 0.28, blue: 0.62) // lapis
        ),
        .init(
            title: "Crystal 4",
            subtitle: "Soft spacious sustain",
            fileName: "focus-crystal gompa-4",
            durationLabel: "1m 50s",
            tint: Color(red: 0.14, green: 0.44, blue: 0.26) // green
        ),
        .init(
            title: "Crystal 5",
            subtitle: "Longer reflective tone",
            fileName: "focus-crystal bowls-5",
            durationLabel: "1m 27s",
            tint: Color(red: 0.70, green: 0.52, blue: 0.12) // gold
        ),
        .init(
            title: "Nun Monlam",
            subtitle: "Prayer and contemplative recitation",
            fileName: "focus-nuns recite at monlam, Mahabodhi",
            durationLabel: "1m 45s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10) // deep red
        )
    ]

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.11, blue: 0.09),
                    Color(red: 0.12, green: 0.10, blue: 0.08),
                    Color(red: 0.08, green: 0.10, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.93, blue: 0.86),
                    Color(red: 0.92, green: 0.91, blue: 0.84),
                    Color(red: 0.90, green: 0.91, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Meditative sounds")
                        .font(.title3.weight(.semibold))

                    Text("An evolving collection of carefully composed sounds for practice, settling, and rest. This is a quiet support space - not a content library.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Sounds") {
                ForEach(sounds) { sound in
                    Button {
                        player.toggle(id: sound.id, fileName: sound.fileName)
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(sound.tint.opacity(0.22))
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Image(systemName: player.isPlaying(id: sound.id) ? "pause.fill" : "play.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(sound.tint)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(sound.title)
                                    .foregroundStyle(.primary)

                                Text(sound.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 3) {
                                Text(sound.durationLabel)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if player.currentID == sound.id {
                                    Image(systemName: player.isPlaying(id: sound.id) ? "waveform" : "speaker.slash")
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(sound.tint)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Later") {
                Text("Sleep and longer listening can live here later without changing the overall structure.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(backgroundGradient.ignoresSafeArea())
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
}

private struct FocusSoundItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let fileName: String
    let durationLabel: String
    let tint: Color

    init(title: String, subtitle: String, fileName: String, durationLabel: String, tint: Color) {
        self.id = fileName
        self.title = title
        self.subtitle = subtitle
        self.fileName = fileName
        self.durationLabel = durationLabel
        self.tint = tint
    }
}

