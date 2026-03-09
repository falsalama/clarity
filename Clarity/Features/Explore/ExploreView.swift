import SwiftUI

struct ExploreView: View {
    private let meditationGold = Color(red: 0.84, green: 0.70, blue: 0.24)
    private let guidanceGreen = Color(red: 0.18, green: 0.46, blue: 0.28)
    private let focusBlue = Color(red: 0.16, green: 0.36, blue: 0.78)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    NavigationLink {
                        MeditationZoneView()
                    } label: {
                        ExplorePillCTA(
                            title: "Meditation Zone",
                            subtitle: "Timer, posture, shamatha, and recitation",
                            systemImage: "figure.mind.and.body",
                            fill: meditationGold
                        )
                    }
                    .buttonStyle(.plain)

                    Text("A quiet space for sitting practice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    NavigationLink {
                        GuidanceHubView()
                    } label: {
                        ExplorePillCTA(
                            title: "Guidance",
                            subtitle: "Book a one-to-one session with a trained Buddhist",
                            systemImage: "person.2.fill",
                            fill: guidanceGreen
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Connect with teachers, practitioners, and future one-to-one offerings. Some options may also help support monasteries, nunneries, and universities.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    FocusSoundsHubView()
                } label: {
                    ExplorePillCTA(
                        title: "Focus",
                        subtitle: "Meditative sounds",
                        systemImage: "waveform",
                        fill: focusBlue
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    TextsView()
                } label: {
                    ExplorePillCTA(
                        title: "Texts",
                        subtitle: "Sutras, prayers, and recitations",
                        systemImage: "book.closed",
                        fill: Color(red: 0.38, green: 0.13, blue: 0.14)
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Coming Soon")
                        .font(.headline)

                    ExplorePlainLink(title: "Teachings", subtitle: "Curated teachings and structured learning will appear here.", systemImage: "book.pages") {
                        ExplorePlaceholderView(
                            title: "Teachings",
                            subtitle: "Curated teachings and structured learning will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Podcast", subtitle: "Talks, conversations, and reflective audio will appear here.", systemImage: "mic.circle") {
                        ExplorePlaceholderView(
                            title: "Podcast",
                            subtitle: "Talks, conversations, and reflective audio will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Videos", subtitle: "Selected video teachings and visual guidance will appear here.", systemImage: "play.rectangle") {
                        ExplorePlaceholderView(
                            title: "Videos",
                            subtitle: "Selected video teachings and visual guidance will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Courses", subtitle: "Longer guided pathways and future modules will appear here.", systemImage: "square.stack.3d.up") {
                        ExplorePlaceholderView(
                            title: "Courses",
                            subtitle: "Longer guided pathways and future modules will appear here."
                        )
                    }

                    ExplorePlainLink(title: "Shop", subtitle: "Future books, practice items, and selected merchandise may appear here.", systemImage: "bag") {
                        ExplorePlaceholderView(
                            title: "Shop",
                            subtitle: "Future books, practice items, and selected merchandise may appear here."
                        )
                    }

                    ExplorePlainLink(title: "Make an Offering", subtitle: "Support places of practice, learning, and preservation", systemImage: "seal.fill") {
                        ExplorePlaceholderView(
                            title: "Make an Offering",
                            subtitle: "A future space for supporting monasteries, nunneries, universities, and authentic practice communities."
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExplorePillCTA: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let fill: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.footnote)
                    .opacity(0.9)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .opacity(0.85)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .foregroundStyle(.white)
        .background(fill)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }
}

private struct ExplorePlainLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @ViewBuilder let destination: () -> Destination

    private let comingSoonBlue = Color(red: 0.16, green: 0.36, blue: 0.78)

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(comingSoonBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(comingSoonBlue.opacity(0.75))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
    }
}

private struct ExplorePlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            Text("Coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
