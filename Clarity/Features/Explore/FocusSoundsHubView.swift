import SwiftUI

struct FocusSoundsHubView: View {
    @ObservedObject private var player = FocusAudioPlayer.shared
    
    private let sounds: [FocusSoundItem] = [
        .init(
            title: "Singing Bowl",
            subtitle: "simple focus sound",
            fileName: "singing-bowl",
            durationLabel: "1m 27s",
            tint: Color(red: 0.70, green: 0.52, blue: 0.12) // gold
        ),
        .init(
            title: "Crystal Cave",
            subtitle: "settling spacious tones",
            fileName: "focus-crystal cave-1",
            durationLabel: "1m 38s",
            tint: Color(red: 0.78, green: 0.58, blue: 0.10) // saffron
        ),
        .init(
            title: "Crystal Shell",
            subtitle: "Clear resonant pace",
            fileName: "focus-crystal shell-2",
            durationLabel: "1m 29s",
            tint: Color(red: 0.55, green: 0.10, blue: 0.14) // maroon
        ),
        .init(
            title: "Crystal Chant",
            subtitle: "Held meditative shimmer",
            fileName: "focus-crystal chant-3",
            durationLabel: "1m 29s",
            tint: Color(red: 0.16, green: 0.28, blue: 0.62) // lapis
        ),
        .init(
            title: "Crystal Gompa",
            subtitle: "Soft spacious sustain",
            fileName: "focus-crystal gompa-4",
            durationLabel: "1m 50s",
            tint: Color(red: 0.14, green: 0.44, blue: 0.26) // green
        ),
        .init(
            title: "Crystal bowls",
            subtitle: "Longer reflective tone",
            fileName: "focus-crystal bowls-5",
            durationLabel: "1m 27s",
            tint: Color(red: 0.70, green: 0.52, blue: 0.12) // gold
        ),
        .init(
            title: "Nun Monlam",
            subtitle: "Prayer and contemplative recitation",
            fileName: "focus-nun-monlam",
            durationLabel: "1m 45s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10) // deep red
        ),
        .init(
            title: "Pristine Space",
            subtitle: "Clear vast space",
            fileName: "pristine-space",
            durationLabel: "3m 27s",
            tint: Color(red: 0.55, green: 0.10, blue: 0.14) // maroon
        ),
        .init(
            title: "Pristine Space-2",
            subtitle: "Vast Expanse",
            fileName: "pristine-space-2",
            durationLabel: "4m 00s",
            tint: Color(red: 0.70, green: 0.52, blue: 0.12) // gold
        ),
        .init(
            title: "Untangle",
            subtitle: "open focus field",
            fileName: "untangle",
            durationLabel: "4m 16s",
            tint: Color(red: 0.16, green: 0.28, blue: 0.62) // lapis
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
            Section("Sounds") {
                ForEach(sounds) { sound in
                    Button {
                        player.toggle(id: sound.id, fileName: sound.fileName)
                    } label: {
                        HStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(sound.tint.opacity(0.22))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: player.isPlaying(id: sound.id) ? "pause.fill" : "play.fill")
                                        .font(.system(size: 12, weight: .semibold))
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
                        .padding(.vertical, 0)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
                }
            }

            Section("Later") {
                Button {
                    player.toggle(id: "Nothing To Hold", fileName: "Nothing To Hold")
                } label: {
                    HStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.42, green: 0.08, blue: 0.10).opacity(0.22))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: player.isPlaying(id: "Nothing To Hold") ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.42, green: 0.08, blue: 0.10))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nothing To Hold")
                                .foregroundStyle(.primary)

                            Text("Preview from the upcoming Longchen Dzo album.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("7m 56s")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            if player.currentID == "Nothing To Hold" {
                                Image(systemName: player.isPlaying(id: "Nothing To Hold") ? "waveform" : "speaker.slash")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Color(red: 0.42, green: 0.08, blue: 0.10))
                            }
                        }
                    }
                    .padding(.vertical, 0)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))

                Text("Sleep, relaxation, and curated songs coming soon.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Meditative Sounds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Meditative Sounds")
                    .font(.headline)
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
