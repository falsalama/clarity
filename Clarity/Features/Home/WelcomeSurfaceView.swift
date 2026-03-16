import SwiftUI
import UIKit

/// Daily photo + message surface (formerly HomeView).
/// Presented full-screen by HomeView wrapper.
struct WelcomeSurfaceView: View {
    @EnvironmentObject private var homeSurface: HomeSurfaceStore

    var body: some View {
        ZStack {
            backgroundImage
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.00),
                    .black.opacity(0.06),
                    .black.opacity(0.18),
                    .black.opacity(0.34),
                    .black.opacity(0.56),
                    .black.opacity(0.78)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let width = geo.size.width
                let topSafe = geo.safeAreaInsets.top

                let pad = horizontalPadding(for: width)
                let contentWidth = max(0, width - (pad * 2))
                let textWidth = min(560, contentWidth)

                ZStack(alignment: .topTrailing) {
                    if dailyUIImage != nil {
                        WelcomeLogoSlot(
                            imagePath: homeSurface.cachedImageFileURL?.path
                        )
                        .padding(.top, topSafe + WelcomeLogoStyle.topOffset)          // MARK: tweak
                        .padding(.trailing, pad + WelcomeLogoStyle.trailingOffset)   // MARK: tweak
                    }

                    VStack {
                        Spacer()

                        VStack(spacing: 10) {
                            if !isShowingStaleWelcome,
                               let message = homeSurface.manifest?.message,
                               !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

                                Text(wrapped(message))
                                    .font(.system(size: responsiveFontSize(for: width),
                                                  weight: .regular,
                                                  design: .serif))
                                    .italic()
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: textWidth, alignment: .center)
                            }

                            if !isShowingStaleWelcome,
                               let a = homeSurface.manifest?.attribution,
                               !a.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

                                Text(wrappedAttribution(a))
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.90))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: textWidth, alignment: .center)
                            }
                        }
                        .padding(.horizontal, pad)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, topSafe + 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .contentShape(Rectangle())
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 16)
        }
        .contextMenu {
            dailyContextMenu
        } preview: {
            if let img = dailyUIImage {
                ZStack {
                    Color.black
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                }
            }
        }
    }

    private var todayDateKey: String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar.current
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private var isShowingStaleWelcome: Bool {
        guard let manifest = homeSurface.manifest else { return false }
        return manifest.dateKey != todayDateKey
    }

    // MARK: - Background

    private var backgroundImage: some View {
        GeometryReader { geo in
            Group {
                if let img = dailyUIImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .contentShape(Rectangle())
                } else {
                    Color(.secondarySystemBackground)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .overlay(ProgressView().progressViewStyle(.circular))
                }
            }
        }
    }

    private var dailyUIImage: UIImage? {
        guard !isShowingStaleWelcome else { return nil }
        guard let url = homeSurface.cachedImageFileURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - Layout helpers

    private func responsiveFontSize(for width: CGFloat) -> CGFloat {
        let scaled = width * 0.105
        return min(46, max(24, scaled))
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        max(22, min(44, width * 0.085))
    }

    // MARK: - Forced wrapping rules

    private func wrapped(_ input: String) -> String {
        wrapWords(input, maxCharsPerLine: 24, maxWordsPerLine: 3)
    }

    private func wrappedAttribution(_ input: String) -> String {
        wrapWords(input, maxCharsPerLine: 28, maxWordsPerLine: 4)
    }

    private func wrapWords(_ input: String, maxCharsPerLine: Int, maxWordsPerLine: Int) -> String {
        let cleaned = input
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .split(whereSeparator: { $0 == " " })
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !cleaned.isEmpty else { return "" }

        var lines: [String] = []
        var currentWords: [String] = []
        var currentLen = 0

        func flushLine() {
            if !currentWords.isEmpty {
                lines.append(currentWords.joined(separator: " "))
                currentWords.removeAll(keepingCapacity: true)
                currentLen = 0
            }
        }

        for w in cleaned {
            if w.count > maxCharsPerLine {
                flushLine()
                lines.append(w)
                continue
            }

            let wordCountWouldBe = currentWords.count + 1
            let extraSpace = currentWords.isEmpty ? 0 : 1
            let lenWouldBe = currentLen + extraSpace + w.count

            let wouldExceedChars = lenWouldBe > maxCharsPerLine
            let wouldExceedWords = wordCountWouldBe > maxWordsPerLine

            if wouldExceedChars || wouldExceedWords {
                flushLine()
            }

            if currentWords.isEmpty {
                currentWords = [w]
                currentLen = w.count
            } else {
                currentWords.append(w)
                currentLen += 1 + w.count
            }
        }

        flushLine()
        return lines.joined(separator: "\n")
    }

    // MARK: - Context menu

    @ViewBuilder
    private var dailyContextMenu: some View {
        if let img = dailyUIImage {
            ShareLink(
                item: Image(uiImage: img),
                preview: SharePreview("Daily Image", image: Image(uiImage: img))
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button {
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
            } label: {
                Label("Save to Photos", systemImage: "square.and.arrow.down")
            }
        }
    }
}

private struct WelcomeLogoSlot: View {
    let imagePath: String?

    @State private var opacity: Double = 0

    var body: some View {
        WelcomeLogoOverlay()
            .opacity(opacity)
            .onAppear {
                opacity = 0
                Task { @MainActor in
                    try? await Task.sleep(
                        nanoseconds: UInt64(WelcomeLogoStyle.fadeInDelay * 1_000_000_000) // MARK: tweak
                    )
                    withAnimation(.easeOut(duration: WelcomeLogoStyle.fadeInDuration)) {    // MARK: tweak
                        opacity = WelcomeLogoStyle.maxOpacity                               // MARK: tweak
                    }
                }
            }
            .onChange(of: imagePath) { _, _ in
                opacity = 0
                Task { @MainActor in
                    try? await Task.sleep(
                        nanoseconds: UInt64(WelcomeLogoStyle.fadeInDelay * 1_000_000_000) // MARK: tweak
                    )
                    withAnimation(.easeOut(duration: WelcomeLogoStyle.fadeInDuration)) {    // MARK: tweak
                        opacity = WelcomeLogoStyle.maxOpacity                               // MARK: tweak
                    }
                }
            }
    }
}

private struct WelcomeLogoOverlay: View {
    var body: some View {
        Image(WelcomeLogoStyle.assetName)
            .resizable()
            .scaledToFit()
            .frame(
                width: WelcomeLogoStyle.width,     // MARK: tweak
                height: WelcomeLogoStyle.height    // MARK: tweak
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private enum WelcomeLogoStyle {
    // MARK: - Asset
    static let assetName = "logo"

    // MARK: - Position
    static let topOffset: CGFloat = -20            // MARK: tweak up
    static let trailingOffset: CGFloat = -108       // MARK: tweak right

    // MARK: - Size
    static let width: CGFloat = 250               // MARK: tweak
    static let height: CGFloat = 250              // MARK: tweak

    // MARK: - Opacity
    static let maxOpacity: Double = 1.0         // MARK: tweak

    // MARK: - Timing
    static let fadeInDelay: Double = 1.8         // MARK: tweak
    static let fadeInDuration: Double = 1.1      // MARK: tweak
}
