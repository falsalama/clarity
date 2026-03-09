import SwiftUI

struct PechaReaderView: View {
    let title: String
    let subtitle: String?
    let pages: [PechaPage]

    @State private var selectedIndex = 0
    @State private var displayMode: PechaDisplayMode = .triLingual

    private var currentPage: PechaPage {
        pages[selectedIndex]
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            VStack(spacing: 0) {
                topBar

                TabView(selection: $selectedIndex) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        ScrollView([.vertical, .horizontal], showsIndicators: false) {
                            VStack {
                                PechaCardView(
                                    page: page,
                                    displayMode: displayMode,
                                    isLandscape: isLandscape
                                )
                                .frame(
                                    maxWidth: isLandscape ? min(geo.size.width - 24, 1000) : geo.size.width - 24
                                )
                                .padding(.vertical, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Picker("Display", selection: $displayMode) {
                ForEach(PechaDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var bottomBar: some View {
        HStack {
            Button {
                previousPage()
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .font(.subheadline.weight(.medium))
            }
            .disabled(selectedIndex == 0)

            Spacer()

            Text(pageLabel)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                nextPage()
            } label: {
                Label("Next", systemImage: "chevron.right")
                    .font(.subheadline.weight(.medium))
            }
            .disabled(selectedIndex == pages.count - 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var pageLabel: String {
        if let n = currentPage.pageNumber {
            return "Page \(n)"
        } else {
            return currentPage.section.rawValue.capitalized
        }
    }

    private func previousPage() {
        guard selectedIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedIndex -= 1
        }
    }

    private func nextPage() {
        guard selectedIndex < pages.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedIndex += 1
        }
    }
}

private struct PechaCardView: View {
    let page: PechaPage
    let displayMode: PechaDisplayMode
    let isLandscape: Bool

    private let pechaBlue = Color(red: 0.18, green: 0.26, blue: 0.52)
    private let pechaGold = Color(red: 0.80, green: 0.69, blue: 0.36)

    var body: some View {
        Group {
            switch page.section {
            case .cover:
                coverPage

            case .image:
                imagePage

            default:
                textPage
            }
        }
    }

    private var coverPage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(pechaBlue)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(pechaGold.opacity(0.6), lineWidth: 1.2)
                .padding(14)

            VStack(spacing: 18) {
                Spacer()

                if let imageName = page.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: isLandscape ? 160 : 120)
                        .padding(.horizontal, 30)
                }

                VStack(spacing: 10) {
                    if let title = page.title {
                        Text(title.uppercased())
                            .font(.system(size: isLandscape ? 28 : 20, weight: .semibold, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(pechaGold)
                            .padding(.horizontal, 24)
                            .minimumScaleFactor(0.7)
                    }

                    if let tibetan = page.tibetan, !tibetan.isEmpty {
                        Text(tibetan)
                            .font(isLandscape ? .title3 : .body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(pechaGold)
                            .padding(.horizontal, 24)
                            .minimumScaleFactor(0.7)
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .frame(height: isLandscape ? 320 : 260)
    }

    private var imagePage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.97, green: 0.96, blue: 0.93))

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)

            if let imageName = page.imageName {
                Image(imageName)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(isLandscape ? 28 : 20)
            }
        }
        .frame(height: isLandscape ? 320 : 260)
    }

    private var textPage: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)

            VStack(alignment: .leading, spacing: textSpacing) {
                if let title = page.title {
                    Text(title)
                        .font(.system(size: isLandscape ? 24 : 20, weight: .semibold, design: .serif))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 2)
                }

                switch displayMode {
                case .triLingual:
                    if let tibetan = page.tibetan, !tibetan.isEmpty {
                        Text(tibetan)
                            .font(tibetanFont)
                            .lineSpacing(isLandscape ? 6 : 7)
                    }

                    if let transliteration = page.transliteration, !transliteration.isEmpty {
                        Text(transliteration)
                            .font(isLandscape ? .footnote : .subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                            .lineSpacing(isLandscape ? 4 : 5)
                    }

                    if let english = page.english, !english.isEmpty {
                        Text(english)
                            .font(englishFont)
                            .lineSpacing(isLandscape ? 5 : 6)
                    }

                case .englishOnly:
                    if let english = page.english, !english.isEmpty {
                        Text(english)
                            .font(englishFont)
                            .lineSpacing(isLandscape ? 6 : 7)
                    }

                case .tibetanOnly:
                    if let tibetan = page.tibetan, !tibetan.isEmpty {
                        Text(tibetan)
                            .font(tibetanFont)
                            .lineSpacing(isLandscape ? 8 : 9)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, isLandscape ? 26 : 18)
            .padding(.top, isLandscape ? 22 : 18)
            .padding(.bottom, isLandscape ? 28 : 26)

            if let n = page.pageNumber {
                Text("\(n)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 18)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, minHeight: isLandscape ? 320 : 420, alignment: .topLeading)
    }

    private var tibetanFont: Font {
        isLandscape ? .title3 : .title2
    }

    private var englishFont: Font {
        isLandscape ? .body : .title3
    }

    private var textSpacing: CGFloat {
        isLandscape ? 14 : 16
    }
}
