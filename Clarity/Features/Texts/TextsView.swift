import SwiftUI

struct TextsView: View {
    @State private var revealPoint: CGPoint? = nil
    @State private var revealAmount: CGFloat = 0
    @State private var contentVisible = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextsBackgroundView(
                revealPoint: revealPoint,
                revealAmount: revealAmount,
                revealSize: 320
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    headerBlock

                    VStack(alignment: .leading, spacing: 14) {
                        NavigationLink {
                            PechaReaderView(
                                title: RefugePrayerPecha.title,
                                subtitle: RefugePrayerPecha.subtitle,
                                pages: RefugePrayerPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Refuge Prayer",
                                titleSecondary: "སྐྱབས་འགྲོ།",
                                subtitle: "A short daily refuge prayer for grounding intention and direction.",
                                category: "Prayer",
                                tint: Color(red: 0.70, green: 0.52, blue: 0.12),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: HeartSutraPecha.title,
                                subtitle: HeartSutraPecha.subtitle,
                                pages: HeartSutraPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Heart Sutra",
                                titleSecondary: "ཤེས་རབ་སྙིང་པོ།",
                                subtitle: "A pecha-style reading edition for practice and recitation.",
                                category: "Sutra",
                                tint: Color(red: 0.55, green: 0.10, blue: 0.14),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: DiamondCutterPecha.title,
                                subtitle: DiamondCutterPecha.subtitle,
                                pages: DiamondCutterPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Diamond Sutra",
                                titleSecondary: "རྡོ་རྗེ་གཅོད་པ།",
                                subtitle: "Opening movement of a Clarity working edition.",
                                category: "Sutra",
                                tint: Color(red: 0.38, green: 0.18, blue: 0.08),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: BodhicittaPrayerPecha.title,
                                subtitle: BodhicittaPrayerPecha.subtitle,
                                pages: BodhicittaPrayerPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Bodhicitta Prayer",
                                titleSecondary: "བྱང་ཆུབ་སེམས།",
                                subtitle: "A short aspiration for bodhicitta to arise, remain, and deepen.",
                                category: "Prayer",
                                tint: Color(red: 0.48, green: 0.22, blue: 0.16),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: ChenrezigPrayerPecha.title,
                                subtitle: ChenrezigPrayerPecha.subtitle,
                                pages: ChenrezigPrayerPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Chenrezig Prayer",
                                titleSecondary: "སྤྱན་རས་གཟིགས།",
                                subtitle: "A short praise with Om Mani Padme Hung.",
                                category: "Prayer",
                                tint: Color(red: 0.66, green: 0.44, blue: 0.20),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: ManjushriPrayerPecha.title,
                                subtitle: ManjushriPrayerPecha.subtitle,
                                pages: ManjushriPrayerPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Manjushri Prayer",
                                titleSecondary: "འཇམ་དཔལ།",
                                subtitle: "A short praise with Om A Ra Pa Tsa Na Dhih.",
                                category: "Prayer",
                                tint: Color(red: 0.58, green: 0.36, blue: 0.14),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: GreenTaraPrayerPecha.title,
                                subtitle: GreenTaraPrayerPecha.subtitle,
                                pages: GreenTaraPrayerPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Green Tara Prayer",
                                titleSecondary: "སྒྲོལ་མ།",
                                subtitle: "A concise Tara supplication with the standard Green Tara mantra.",
                                category: "Prayer",
                                tint: Color(red: 0.18, green: 0.42, blue: 0.22),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: WhiteTaraPrayerPecha.title,
                                subtitle: WhiteTaraPrayerPecha.subtitle,
                                pages: WhiteTaraPrayerPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "White Tara Prayer",
                                titleSecondary: "སྒྲོལ་དཀར།",
                                subtitle: "A short praise with a White Tara longevity mantra.",
                                category: "Prayer",
                                tint: Color(red: 0.60, green: 0.62, blue: 0.70),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())

                        NavigationLink {
                            PechaReaderView(
                                title: DedicationPrayerPecha.title,
                                subtitle: DedicationPrayerPecha.subtitle,
                                pages: DedicationPrayerPecha.pages
                            )
                        } label: {
                            TextCard(
                                title: "Dedication Prayer",
                                titleSecondary: "བསྔོ་བ།",
                                subtitle: "A closing dedication for offering merit and ending practice cleanly.",
                                category: "Prayer",
                                tint: Color(red: 0.16, green: 0.28, blue: 0.62),
                                isAvailable: true
                            )
                        }
                        .buttonStyle(TextCardPressStyle())
                    }
                }
                .padding(16)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 8)
        }
        .coordinateSpace(name: "TextsRevealSpace")
        .onAppear {
            withAnimation(.easeOut(duration: 0.22)) {
                contentVisible = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    startReveal(at: value.location)
                }
                .onEnded { _ in
                    endReveal()
                }
        )
        .navigationTitle("Texts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A small practice library for sutras, prayers, and recitations.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    private func startReveal(at point: CGPoint) {
        revealPoint = point
        withAnimation(.easeOut(duration: 0.14)) {
            revealAmount = 1
        }
    }

    private func endReveal() {
        withAnimation(.easeOut(duration: 0.80)) {
            revealAmount = 0
        }
    }
}

private struct TextsBackgroundView: View {
    let revealPoint: CGPoint?
    let revealAmount: CGFloat
    let revealSize: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundImage(named: "textbg", in: proxy)
                    .opacity(0.70)

                if let revealPoint {
                    backgroundImage(named: "textbgcol", in: proxy)
                        .opacity(revealAmount * 0.70)
                        .mask {
                            ZStack {
                                Color.clear

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            stops: [
                                                .init(color: .white.opacity(1.0), location: 0.00),
                                                .init(color: .white.opacity(0.92), location: 0.20),
                                                .init(color: .white.opacity(0.70), location: 0.42),
                                                .init(color: .white.opacity(0.34), location: 0.68),
                                                .init(color: .clear, location: 1.00)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: revealSize * (0.46 + (revealAmount * 0.10))
                                        )
                                    )
                                    .frame(
                                        width: revealSize * (0.94 + revealAmount * 0.08),
                                        height: revealSize * (0.94 + revealAmount * 0.08)
                                    )
                                    .position(revealPoint)
                                    .blur(radius: 24)
                            }
                            .compositingGroup()
                        }
                }
            }
        }
    }

    private func backgroundImage(named name: String, in proxy: GeometryProxy) -> some View {
        let overscanWidth = proxy.size.width * 1.14
        let overscanHeight = proxy.size.height * 1.26
        let image = Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: overscanWidth, height: overscanHeight)
            .offset(y: proxy.size.height * 0.07)
            .clipped()
            .ignoresSafeArea()

        return image
    }
}

private struct TextCard: View {
    let title: String
    let titleSecondary: String?
    let subtitle: String
    let category: String
    let tint: Color
    let isAvailable: Bool

    init(
        title: String,
        titleSecondary: String? = nil,
        subtitle: String,
        category: String,
        tint: Color,
        isAvailable: Bool
    ) {
        self.title = title
        self.titleSecondary = titleSecondary
        self.subtitle = subtitle
        self.category = category
        self.tint = tint
        self.isAvailable = isAvailable
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let titleSecondary, !titleSecondary.isEmpty {
                        Text(titleSecondary)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(category)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            Spacer()

            if isAvailable {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            } else {
                Text("Soon")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct TextCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        Color.primary.opacity(configuration.isPressed ? 0.30 : 0.18),
                        lineWidth: configuration.isPressed ? 1.5 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.992 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
