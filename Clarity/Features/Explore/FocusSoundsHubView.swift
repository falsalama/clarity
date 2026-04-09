import SwiftUI
import UIKit

struct FocusSoundsHubView: View {
    @ObservedObject private var player = FocusAudioPlayer.shared

    private let longchenSongID = "Nothing To Hold"
    private let longchenSongTint = Color(red: 0.42, green: 0.08, blue: 0.10)
    
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
                featuredLongchenSongRow

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

extension FocusSoundsHubView {
    private var featuredLongchenSongRow: some View {
        Button {
            player.toggle(id: longchenSongID, fileName: longchenSongID)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.97, blue: 0.94).opacity(colorScheme == .dark ? 0.10 : 0.92),
                                Color(red: 0.92, green: 0.89, blue: 0.84).opacity(colorScheme == .dark ? 0.12 : 0.86),
                                Color(red: 0.83, green: 0.78, blue: 0.72).opacity(colorScheme == .dark ? 0.14 : 0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if UIImage(named: "cloudbg") != nil {
                    Image("cloudbg")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(1.12)
                        .opacity(colorScheme == .dark ? 0.28 : 0.40)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.24),
                                Color(red: 0.71, green: 0.62, blue: 0.48).opacity(colorScheme == .dark ? 0.10 : 0.20),
                                longchenSongTint.opacity(colorScheme == .dark ? 0.26 : 0.14),
                                Color.black.opacity(colorScheme == .dark ? 0.12 : 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RadialGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.34),
                        Color(red: 0.86, green: 0.75, blue: 0.57).opacity(colorScheme == .dark ? 0.08 : 0.16),
                        .clear
                    ],
                    center: .topLeading,
                    startRadius: 18,
                    endRadius: 180
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(longchenSongTint.opacity(0.20))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: player.isPlaying(id: longchenSongID) ? "pause.fill" : "play.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(longchenSongTint)
                            )
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Featured Song")
                                .font(.caption.weight(.bold))
                                .tracking(1.0)
                                .foregroundStyle(longchenSongTint.opacity(0.96))

                            Text("Nothing To Hold")
                                .font(.system(.title3, design: .serif).weight(.bold))
                                .foregroundStyle(.primary)

                            Text("Preview from the upcoming Longchen Dzó album.")
                                .font(.footnote)
                                .foregroundStyle(.primary.opacity(0.72))
                                .lineLimit(2)
                        }

                        Spacer(minLength: 12)

                        VStack(alignment: .trailing, spacing: 6) {
                            Text("7m 56s")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.primary.opacity(0.68))

                            if player.currentID == longchenSongID {
                                Label(
                                    player.isPlaying(id: longchenSongID) ? "Playing" : "Paused",
                                    systemImage: player.isPlaying(id: longchenSongID) ? "waveform" : "speaker.slash"
                                )
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(longchenSongTint)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Text("Longchen Dzó")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary.opacity(0.78))

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        longchenSongTint.opacity(0.34),
                                        Color.white.opacity(0.10)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.16 : 0.58),
                                longchenSongTint.opacity(colorScheme == .dark ? 0.34 : 0.26),
                                Color(red: 0.82, green: 0.70, blue: 0.50).opacity(colorScheme == .dark ? 0.16 : 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: longchenSongTint.opacity(colorScheme == .dark ? 0.08 : 0.14), radius: 14, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 6, trailing: 10))
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
