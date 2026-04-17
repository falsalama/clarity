import SwiftUI

struct PechaReaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String?
    let pages: [PechaPage]

    @State private var selectedIndex = 0

    private var readablePages: [PechaPage] {
        pages.filter { $0.section != .cover }
    }

    private var readerTheme: PechaReaderTheme {
        guard colorScheme == .dark else { return .default }

        switch title {
        case HeartSutraPecha.title:
            return .heartSutraDark
        case DiamondCutterPecha.title:
            return .diamondCutterDark
        default:
            return .default
        }
    }

    private var usesThemedNavigationTitle: Bool {
        colorScheme == .dark && (title == HeartSutraPecha.title || title == DiamondCutterPecha.title)
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let availableWidth = max(geo.size.width, 0)
            let landscapeControlGutter: CGFloat = isLandscape ? 58 : 0
            let pageWidth = isLandscape
                ? min(max(availableWidth - 28 - (landscapeControlGutter * 2), 0), 1080)
                : max(availableWidth - 20, 0)

            Group {
                if isLandscape {
                    landscapePagedReader(pageWidth: pageWidth, sideGutter: landscapeControlGutter)
                } else {
                    portraitScrollingReader(pageWidth: pageWidth)
                }
            }
            .background(readerTheme.background.ignoresSafeArea())
            .navigationTitle(title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if usesThemedNavigationTitle {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(readerTheme.primaryText)
                            .lineLimit(1)
                    }
                }
            }
#endif
#if os(iOS)
            .toolbar(.hidden, for: .tabBar)
#endif
        }
    }

    private func portraitScrollingReader(pageWidth: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 18) {
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(readerTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 2)
                }

                ForEach(Array(readablePages.enumerated()), id: \.element.id) { index, page in
                    VStack(alignment: .leading, spacing: 10) {
                        PechaPagePanel(page: page, isLandscape: false, theme: readerTheme)

                        if index < readablePages.count - 1 {
                            Divider()
                                .overlay(readerTheme.divider.opacity(0.75))
                                .padding(.top, 8)
                        }
                    }
                }
            }
            .frame(maxWidth: pageWidth, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func landscapePagedReader(pageWidth: CGFloat, sideGutter: CGFloat) -> some View {
        ZStack {
            TabView(selection: $selectedIndex) {
                ForEach(Array(readablePages.enumerated()), id: \.element.id) { index, page in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            if index == 0, let subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(readerTheme.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 2)
                            }

                            PechaPagePanel(page: page, isLandscape: true, theme: readerTheme)
                        }
                        .frame(maxWidth: pageWidth, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 18)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.22), value: selectedIndex)

            HStack {
                pageArrowButton(direction: .previous)
                Spacer(minLength: 16)
                pageArrowButton(direction: .next)
            }
            .padding(.horizontal, max(sideGutter - 12, 12))
        }
        .overlay(alignment: .bottom) {
            if readablePages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(readablePages.indices, id: \.self) { index in
                        Capsule(style: .continuous)
                            .fill(index == selectedIndex ? readerTheme.primaryText.opacity(0.72) : readerTheme.secondaryText.opacity(0.28))
                            .frame(width: index == selectedIndex ? 18 : 6, height: 6)
                    }
                }
                .padding(.bottom, 10)
            }
        }
    }

    @ViewBuilder
    private func pageArrowButton(direction: PageDirection) -> some View {
        let canMove = direction == .previous ? selectedIndex > 0 : selectedIndex < readablePages.count - 1

        Button {
            guard canMove else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedIndex += direction == .previous ? -1 : 1
            }
        } label: {
            Image(systemName: direction == .previous ? "chevron.left" : "chevron.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(canMove ? readerTheme.primaryText.opacity(0.82) : readerTheme.secondaryText.opacity(0.35))
                .frame(width: 40, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(readerTheme.arrowBackground.opacity(0.68))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(readerTheme.primaryText.opacity(canMove ? 0.10 : 0.05), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canMove)
        .accessibilityLabel(direction == .previous ? "Previous page" : "Next page")
    }
}

private enum PageDirection {
    case previous
    case next
}

private struct PechaPagePanel: View {
    @Environment(\.colorScheme) private var colorScheme

    let page: PechaPage
    let isLandscape: Bool
    let theme: PechaReaderTheme

    private var isMantraPage: Bool {
        page.section == .mantra
    }

    private var isHeartSutraMantraPage: Bool {
        page.id == "heart-mantra-14"
    }

    private var isShortPrayerPage: Bool {
        page.id == "refuge-prayer-main" || page.id == "dedication-prayer-main"
    }

    private var isTitlePage: Bool {
        page.section == .title
    }

    private var tibetanLines: [String] {
        splitLines(page.tibetan)
    }

    private var transliterationLines: [String] {
        splitLines(page.transliteration)
    }

    private var englishLines: [String] {
        splitLines(page.english)
    }

    private var canInterleaveTriLingual: Bool {
        let count = tibetanLines.count
        return count > 0 && transliterationLines.count == count && englishLines.count == count
    }

    private var resolvedImageName: String? {
        guard let imageName = page.imageName else { return nil }

        if imageName == "heart-sutra-woodblock", colorScheme == .dark {
            return "heart-sutra-woodblock-dark"
        }

        return imageName
    }

    var body: some View {
        switch page.section {
        case .cover:
            EmptyView()

        case .image:
            if let imageName = resolvedImageName {
                Image(imageName)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: isLandscape ? 300 : 240)
                    .padding(.vertical, 8)
            }

        case .title:
            titlePageContent

        default:
            VStack(alignment: .leading, spacing: isLandscape ? 12 : 10) {
                if let title = page.title, !title.isEmpty {
                    Text(title)
                        .font(
                            .system(
                                size: isMantraPage ? (isLandscape ? 32 : 28) : (isLandscape ? 28 : 24),
                                weight: isMantraPage ? .bold : .semibold,
                                design: .serif
                            )
                        )
                        .foregroundStyle(theme.primaryText)
                        .padding(.bottom, 2)
                }

                if canInterleaveTriLingual {
                    VStack(alignment: .leading, spacing: isLandscape ? 14 : 12) {
                        ForEach(Array(tibetanLines.enumerated()), id: \.offset) { index, tibetan in
                            VStack(alignment: .leading, spacing: isLandscape ? 4 : 3) {
                                Text(tibetan)
                                    .font(
                                        isMantraPage
                                        ? .system(size: isLandscape ? 26 : 28, weight: .bold, design: .serif)
                                        : .system(
                                            size: isShortPrayerPage
                                                ? (isLandscape ? 24 : 26)
                                                : (isLandscape ? 20 : 22),
                                            weight: .regular,
                                            design: .serif
                                        )
                                    )
                                    .foregroundStyle(theme.primaryText)
                                    .lineSpacing(isMantraPage ? (isLandscape ? 6 : 7) : (isLandscape ? 4 : 5))

                                Text(transliterationLines[index])
                                    .font(
                                        isMantraPage
                                        ? .system(size: isLandscape ? 20 : 21, weight: .semibold, design: .serif)
                                        : .system(
                                            size: isShortPrayerPage
                                                ? (isLandscape ? 19 : 20)
                                                : (isLandscape ? 17 : 15),
                                            weight: .regular,
                                            design: .serif
                                        )
                                    )
                                    .italic()
                                    .foregroundStyle(isMantraPage ? theme.primaryText.opacity(0.9) : theme.secondaryText)
                                    .lineSpacing(isMantraPage ? (isLandscape ? 4 : 5) : (isLandscape ? 3 : 4))

                                Text(englishLines[index])
                                    .font(
                                        isMantraPage
                                        ? .system(size: isLandscape ? 22 : 20, weight: .semibold, design: .serif)
                                        : .system(
                                            size: isShortPrayerPage
                                                ? (isLandscape ? 21 : 20)
                                                : (isLandscape ? 20 : 17),
                                            weight: .regular,
                                            design: .serif
                                        )
                                    )
                                    .foregroundStyle(theme.primaryText)
                                    .lineSpacing(isMantraPage ? (isLandscape ? 5 : 6) : (isLandscape ? 4 : 5))
                            }
                        }
                    }
                } else {
                    if let tibetan = page.tibetan, !tibetan.isEmpty {
                        Text(tibetan)
                            .font(
                                isMantraPage
                                ? .system(
                                    size: isHeartSutraMantraPage
                                        ? (isLandscape ? 24 : 26)
                                        : (isLandscape ? 26 : 28),
                                    weight: .bold,
                                    design: .serif
                                )
                                : (isLandscape ? .title3 : .title2)
                            )
                            .foregroundStyle(theme.primaryText)
                            .lineSpacing(isMantraPage ? (isLandscape ? 7 : 8) : (isLandscape ? 6 : 7))
                            .lineLimit(isHeartSutraMantraPage ? 1 : nil)
                            .minimumScaleFactor(isHeartSutraMantraPage ? 0.92 : 1.0)
                    }

                    if let transliteration = page.transliteration, !transliteration.isEmpty {
                        Text(transliteration)
                            .font(
                                isMantraPage
                                ? .system(size: isLandscape ? 20 : 21, weight: .semibold, design: .serif)
                                : (isLandscape ? .body : .subheadline)
                            )
                            .italic()
                            .foregroundStyle(isMantraPage ? theme.primaryText.opacity(0.9) : theme.secondaryText)
                            .lineSpacing(isMantraPage ? (isLandscape ? 5 : 6) : (isLandscape ? 4 : 5))
                    }

                    if let english = page.english, !english.isEmpty {
                        Text(english)
                            .font(
                                isMantraPage
                                ? .system(size: isLandscape ? 22 : 20, weight: .semibold, design: .serif)
                                : (isLandscape ? .title3 : .body)
                            )
                            .foregroundStyle(theme.primaryText)
                            .lineSpacing(isMantraPage ? (isLandscape ? 7 : 8) : (isLandscape ? 6 : 7))
                    }
                }

                if let n = page.pageNumber {
                    Text("Page \(n)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(theme.tertiaryText)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, isMantraPage ? (isLandscape ? 10 : 8) : 0)
            .padding(.vertical, isMantraPage ? (isLandscape ? 8 : 6) : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var titlePageContent: some View {
        VStack(alignment: .leading, spacing: isLandscape ? 20 : 18) {
            if let title = page.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: isLandscape ? 36 : 32, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.leading)
            }

            if let tibetan = page.tibetan, !tibetan.isEmpty {
                Text(tibetan)
                    .font(.system(size: isLandscape ? 34 : 30, weight: .medium, design: .serif))
                    .foregroundStyle(theme.primaryText)
                    .lineSpacing(isLandscape ? 8 : 9)
            }

            if let transliteration = page.transliteration, !transliteration.isEmpty {
                Text(transliteration)
                    .font(.system(size: isLandscape ? 22 : 20, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(theme.secondaryText)
                    .lineSpacing(isLandscape ? 5 : 6)
            }
        }
        .padding(.horizontal, isLandscape ? 28 : 22)
        .padding(.vertical, isLandscape ? 26 : 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            Rectangle()
                .stroke(theme.primaryText.opacity(0.24), lineWidth: 1)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.primaryText.opacity(0.18))
                .frame(height: 1)
                .padding(.horizontal, isLandscape ? 18 : 14)
                .padding(.top, isLandscape ? 10 : 8)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.primaryText.opacity(0.18))
                .frame(height: 1)
                .padding(.horizontal, isLandscape ? 18 : 14)
                .padding(.bottom, isLandscape ? 10 : 8)
        }
    }

    private func splitLines(_ text: String?) -> [String] {
        guard let text else { return [] }
        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct PechaReaderTheme {
    let background: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let divider: Color
    let arrowBackground: Color

    static let `default` = PechaReaderTheme(
        background: Color(.systemBackground),
        primaryText: .primary,
        secondaryText: .secondary,
        tertiaryText: Color(.tertiaryLabel),
        divider: Color.primary.opacity(0.12),
        arrowBackground: Color(.systemBackground)
    )

    static let heartSutraDark = PechaReaderTheme(
        background: Color.black,
        primaryText: Color(red: 0.80, green: 0.67, blue: 0.35),
        secondaryText: Color(red: 0.66, green: 0.56, blue: 0.33),
        tertiaryText: Color(red: 0.52, green: 0.45, blue: 0.28),
        divider: Color(red: 0.46, green: 0.38, blue: 0.16),
        arrowBackground: Color(red: 0.10, green: 0.09, blue: 0.05)
    )

    static let diamondCutterDark = PechaReaderTheme(
        background: Color.black,
        primaryText: Color(red: 0.80, green: 0.82, blue: 0.86),
        secondaryText: Color(red: 0.66, green: 0.70, blue: 0.75),
        tertiaryText: Color(red: 0.50, green: 0.54, blue: 0.60),
        divider: Color(red: 0.48, green: 0.50, blue: 0.56),
        arrowBackground: Color(red: 0.07, green: 0.07, blue: 0.08)
    )
}
