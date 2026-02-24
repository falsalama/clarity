import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var homeSurface: HomeSurfaceStore
    @State private var showFullImage = false
    
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
                let bottomSafe = geo.safeAreaInsets.bottom

                let pad = horizontalPadding(for: width)
                let contentWidth = max(0, width - (pad * 2))
                let textWidth = min(560, contentWidth)

                VStack {
                    Spacer()

                    // Bottom-anchored text block with no hard height cap.
                    VStack(spacing: 10) {

                        if let message = homeSurface.manifest?.message,
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
                                .clipped()
                        }

                        if let a = homeSurface.manifest?.attribution,
                           !a.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

                            Text(wrappedAttribution(a))
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.90))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: textWidth, alignment: .center)
                                .clipped()
                        }
                    }
                    .padding(.horizontal, pad)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.clear)
                    .clipped()

                    let tabClearance: CGFloat = -50
                    let minClearance: CGFloat = 10        // always keep at least 10pt above the tab bar
                    let h = max(minClearance, bottomSafe + tabClearance)

                    Color.clear
                        .frame(height: h)


                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .contentShape(Rectangle())
        .contextMenu { dailyContextMenu }
        // No network refresh here.
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

    // MARK: - Forced wrapping rules (hard guarantee)

    /// Message rules:
    /// - max 24 chars per line
    /// - max 3 words per line
    /// - never split words
    /// - if doubt, line break
    private func wrapped(_ input: String) -> String {
        wrapWords(
            input,
            maxCharsPerLine: 24,
            maxWordsPerLine: 3
        )
    }

    /// Attribution can be slightly looser, but still safe.
    private func wrappedAttribution(_ input: String) -> String {
        wrapWords(
            input,
            maxCharsPerLine: 28,
            maxWordsPerLine: 4
        )
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
            // If a single word is longer than maxCharsPerLine, force it onto its own line.
            // (Still no splitting; this is the least-bad option while honouring your constraint.)
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

            // Add after flush (or to empty line)
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
