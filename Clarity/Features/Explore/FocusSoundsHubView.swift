import SwiftUI

struct FocusSoundsHubView: View {
    @EnvironmentObject private var nowPlaying: NowPlayingStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedID = FocusSoundsLibrary.heroItems.first?.id ?? ""

    private var items: [AudioTrack] {
        FocusSoundsLibrary.all
    }

    private var featuredItems: [AudioTrack] {
        FocusSoundsLibrary.heroItems
    }

    private var longchenDzoItems: [AudioTrack] {
        items.filter { $0.collectionTitle == "Longchen Dzó" }
    }

    private var standardItems: [AudioTrack] {
        items.filter { $0.collectionTitle == nil }
    }

    private var selectedItem: AudioTrack {
        featuredItems.first(where: { $0.id == selectedID }) ?? featuredItems[0]
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = proxy.size.width

            ZStack {
                backgroundLayer

                VStack(spacing: 0) {
                    heroPager(contentWidth: contentWidth)
                        .padding(.top, 12)

                    ScrollView(showsIndicators: false) {
                        playlistSection
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 90)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .navigationTitle("Meditative Sounds")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            nowPlaying.setQueue(items)
            if selectedID.isEmpty, let first = featuredItems.first?.id {
                selectedID = first
            }
            if let currentID = nowPlaying.currentItem?.id,
               items.contains(where: { $0.id == currentID }) {
                selectedID = currentID
            }
        }
        .onChange(of: nowPlaying.currentItem?.id) { _, newValue in
            guard let newValue, items.contains(where: { $0.id == newValue }) else { return }
            selectedID = newValue
        }
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.06, green: 0.07, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.10),
                    Color(red: 0.07, green: 0.09, blue: 0.11)
                ]
                : [
                    Color(red: 0.985, green: 0.985, blue: 0.98),
                    Color(red: 0.972, green: 0.972, blue: 0.968),
                    Color(red: 0.958, green: 0.962, blue: 0.97)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func heroPager(contentWidth: CGFloat) -> some View {
        VStack(spacing: 12) {
            TabView(selection: $selectedID) {
                ForEach(featuredItems) { item in
                    FocusSoundHeroCard(
                        item: item,
                        showsPlayButton: nowPlaying.currentItem?.id != item.id,
                        isCurrent: nowPlaying.currentItem?.id == item.id,
                        isPlaying: nowPlaying.isPlaying
                    ) {
                        selectedID = item.id
                        nowPlaying.play(item, queue: items)
                    }
                    .frame(width: contentWidth, height: contentWidth)
                    .tag(item.id)
                }
            }
            .frame(width: contentWidth, height: contentWidth)
            .clipped()
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(featuredItems) { item in
                    Circle()
                        .fill(item.id == selectedID ? selectedItem.tint.opacity(0.95) : Color.primary.opacity(0.18))
                        .frame(width: item.id == selectedID ? 7 : 6, height: item.id == selectedID ? 7 : 6)
                }
            }
        }
        .frame(width: contentWidth, alignment: .leading)
    }

    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !longchenDzoItems.isEmpty {
                Text("Longchen Dzó")
                    .font(.headline)

                trackList(longchenDzoItems)
            }

            if !standardItems.isEmpty {
                Text("Sounds")
                    .font(.headline)

                trackList(standardItems)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trackList(_ tracks: [AudioTrack]) -> some View {
        VStack(spacing: 10) {
            ForEach(tracks) { item in
                Button {
                    selectedID = item.id
                    nowPlaying.play(item, queue: items)
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(item.tint.opacity(nowPlaying.currentItem?.id == item.id ? 0.24 : 0.14))
                            .frame(width: 10, height: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(item.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(item.durationLabel)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: true, vertical: false)

                            if nowPlaying.currentItem?.id == item.id {
                                Text(nowPlaying.isPlaying ? "Playing" : "Paused")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(item.tint)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                        .frame(minWidth: 52, alignment: .trailing)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground).opacity(nowPlaying.currentItem?.id == item.id ? 0.94 : 0.78))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FocusSoundHeroCard: View {
    let item: AudioTrack
    let showsPlayButton: Bool
    let isCurrent: Bool
    let isPlaying: Bool
    let playAction: () -> Void

    var body: some View {
        ZStack {
            Image(item.artworkAssetName ?? "placeholder5")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            if showsPlayButton {
                Button(action: playAction) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 74, height: 74)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            )

                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    }
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Meditative Sounds")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(Color.white.opacity(0.84))

                    Spacer()

                    if isCurrent {
                        Text(isPlaying ? "Now Playing" : "Paused")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.14))
                            )
                    } else {
                        Text(item.durationLabel)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.78))
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(item.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: playAction)
    }
}

enum FocusSoundsLibrary {
    static let all: [AudioTrack] = [
        .init(
            title: "Nothing To Hold",
            subtitle: "Longchen Dzó preview",
            note: "A spacious reflective song with the same player structure as Teachings.",
            fileName: "Nothing To Hold",
            artworkAssetName: "placeholder20",
            durationLabel: "7m 56s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10),
            collectionTitle: "Longchen Dzó"
        ),
        .init(
            title: "Tears of Samye",
            subtitle: "Longchen Dzó",
            note: "A spacious reflective song with the same player structure as Teachings.",
            fileName: "Tears of Samye",
            artworkAssetName: "placeholder19",
            durationLabel: "0m 00s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10),
            collectionTitle: "Longchen Dzó"
        ),
        .init(
            title: "30 Things to Remember",
            subtitle: "Longchen Dzó",
            note: "A spacious reflective song with the same player structure as Teachings.",
            fileName: "30 things to remember",
            artworkAssetName: "placeholder18",
            durationLabel: "0m 00s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10),
            collectionTitle: "Longchen Dzó"
        ),
        .init(
            title: "Crystal Cave",
            subtitle: "Settling spacious tones",
            note: "Held crystalline tones with a slightly warmer field.",
            fileName: "focus-crystal cave-1",
            artworkAssetName: "placeholder16",
            durationLabel: "1m 38s",
            tint: Color(red: 0.78, green: 0.58, blue: 0.10)
        ),
        .init(
            title: "Crystal Shell",
            subtitle: "Clear resonant pace",
            note: "A clear bell-like pulse with a more defined attack.",
            fileName: "focus-crystal shell-2",
            artworkAssetName: "placeholder17",
            durationLabel: "1m 29s",
            tint: Color(red: 0.55, green: 0.10, blue: 0.14)
        ),
        .init(
            title: "Dakini Code",
            subtitle: "Longchen Dzó",
            note: "A spacious reflective song with the same player structure as Teachings.",
            fileName: "Dakini code",
            artworkAssetName: "placeholder21",
            durationLabel: "0m 00s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10),
            collectionTitle: "Longchen Dzó"
        ),
        .init(
            title: "Vast Drop",
            subtitle: "Longchen Dzó",
            note: "A spacious reflective song with the same player structure as Teachings.",
            fileName: "vast drop",
            artworkAssetName: "placeholder22",
            durationLabel: "0m 00s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10),
            collectionTitle: "Longchen Dzó"
        ),
        .init(
            title: "Crystal Chant",
            subtitle: "Held meditative shimmer",
            note: "A softer continuous shimmer for calm sustained focus.",
            fileName: "focus-crystal chant-3",
            artworkAssetName: "placeholder23",
            durationLabel: "1m 29s",
            tint: Color(red: 0.16, green: 0.28, blue: 0.62)
        ),
        .init(
            title: "Crystal Gompa",
            subtitle: "Soft spacious sustain",
            note: "A deeper room-like resonance with gentle decay.",
            fileName: "focus-crystal gompa-4",
            artworkAssetName: "placeholder24",
            durationLabel: "1m 50s",
            tint: Color(red: 0.14, green: 0.44, blue: 0.26)
        ),
        .init(
            title: "Crystal Bowls",
            subtitle: "Longer reflective tone",
            note: "A rounded layered bowl texture with longer sustain.",
            fileName: "focus-crystal bowls-5",
            artworkAssetName: "placeholder25",
            durationLabel: "1m 27s",
            tint: Color(red: 0.70, green: 0.52, blue: 0.12)
        ),
        .init(
            title: "Nun Monlam",
            subtitle: "Prayer and contemplative recitation",
            note: "Chanted prayer in the same calmer card-based listening format.",
            fileName: "focus-nun-monlam",
            artworkAssetName: "placeholder12",
            durationLabel: "1m 45s",
            tint: Color(red: 0.42, green: 0.08, blue: 0.10)
        ),
        .init(
            title: "Pristine Space",
            subtitle: "Clear vast space",
            note: "An open contemplative atmosphere with spacious decay.",
            fileName: "pristine-space",
            artworkAssetName: "placeholder13",
            durationLabel: "3m 27s",
            tint: Color(red: 0.55, green: 0.10, blue: 0.14)
        ),
        .init(
            title: "Pristine Space-2",
            subtitle: "Vast expanse",
            note: "A longer variation with a slower widening field.",
            fileName: "pristine-space-2",
            artworkAssetName: "placeholder14",
            durationLabel: "4m 00s",
            tint: Color(red: 0.70, green: 0.52, blue: 0.12)
        ),
        .init(
            title: "Untangle",
            subtitle: "Open focus field",
            note: "A more active ambient track for loosening attention gently.",
            fileName: "untangle",
            artworkAssetName: "placeholder15",
            durationLabel: "4m 16s",
            tint: Color(red: 0.16, green: 0.28, blue: 0.62)
        ),
        .init(
            title: "Singing Bowl",
            subtitle: "Simple focus sound",
            note: "A single resonant bowl tone for settling attention.",
            fileName: "singing-bowl",
            artworkAssetName: "placeholder6",
            durationLabel: "1m 27s",
            tint: Color(red: 0.70, green: 0.52, blue: 0.12)
        )
    ]

    static let heroItems: [AudioTrack] = all
}
