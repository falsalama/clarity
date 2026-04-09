import SwiftUI

struct PechaReaderView: View {
    let title: String
    let subtitle: String?
    let pages: [PechaPage]

    @State private var selectedIndex = 0

    private var readablePages: [PechaPage] {
        pages.filter { $0.section != .cover }
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let availableWidth = max(geo.size.width, 0)
            let pageWidth = isLandscape ? min(max(availableWidth - 28, 0), 1180) : max(availableWidth - 20, 0)

            TabView(selection: $selectedIndex) {
                ForEach(Array(readablePages.enumerated()), id: \.element.id) { index, page in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            if index == 0, let subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 2)
                            }

                            PechaPagePanel(page: page, isLandscape: isLandscape)
                        }
                        .frame(maxWidth: pageWidth, alignment: .leading)
                        .padding(.horizontal, isLandscape ? 14 : 10)
                        .padding(.top, 8)
                        .padding(.bottom, 18)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}

private struct PechaPagePanel: View {
    let page: PechaPage
    let isLandscape: Bool

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

    var body: some View {
        switch page.section {
        case .cover:
            EmptyView()

        case .image:
            if let imageName = page.imageName {
                Image(imageName)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: isLandscape ? 300 : 240)
                    .padding(.vertical, 8)
            }

        default:
            VStack(alignment: .leading, spacing: isLandscape ? 12 : 10) {
                if let title = page.title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: isLandscape ? 28 : 24, weight: .semibold, design: .serif))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 2)
                }

                if canInterleaveTriLingual {
                    VStack(alignment: .leading, spacing: isLandscape ? 14 : 12) {
                        ForEach(Array(tibetanLines.enumerated()), id: \.offset) { index, tibetan in
                            VStack(alignment: .leading, spacing: isLandscape ? 4 : 3) {
                                Text(tibetan)
                                    .font(isLandscape ? .title3 : .title2)
                                    .lineSpacing(isLandscape ? 4 : 5)

                                Text(transliterationLines[index])
                                    .font(isLandscape ? .body : .subheadline)
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(isLandscape ? 3 : 4)

                                Text(englishLines[index])
                                    .font(isLandscape ? .title3 : .body)
                                    .lineSpacing(isLandscape ? 4 : 5)
                            }
                        }
                    }
                } else {
                    if let tibetan = page.tibetan, !tibetan.isEmpty {
                        Text(tibetan)
                            .font(isLandscape ? .title3 : .title2)
                            .lineSpacing(isLandscape ? 6 : 7)
                    }

                    if let transliteration = page.transliteration, !transliteration.isEmpty {
                        Text(transliteration)
                            .font(isLandscape ? .body : .subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                            .lineSpacing(isLandscape ? 4 : 5)
                    }

                    if let english = page.english, !english.isEmpty {
                        Text(english)
                            .font(isLandscape ? .title3 : .body)
                            .lineSpacing(isLandscape ? 6 : 7)
                    }
                }

                if let n = page.pageNumber {
                    Text("Page \(n)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
