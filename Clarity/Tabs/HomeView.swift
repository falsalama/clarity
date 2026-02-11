import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var welcome: WelcomeSurfaceStore

    var body: some View {
        ZStack {
            // Full-bleed background (under nav bar + tab bar)
            backgroundImage
                .ignoresSafeArea()

            // Readability gradient (under text, still full-bleed)
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

            // Foreground content layer
            GeometryReader { geo in
                let width = geo.size.width
                let bottomSafe = geo.safeAreaInsets.bottom
                let maxContentWidth = min(width * 0.9, 560)

                VStack {
                    Spacer()

                    VStack(spacing: 10) {
                        Text(welcome.manifest?.message ?? "Welcome")
                            .font(.system(size: responsiveFontSize(for: width),
                                          weight: .regular,
                                          design: .serif))
                            .italic()
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)                  // wrap up to 4 lines
                            .minimumScaleFactor(0.6)       // allow shrink to fit
                            .allowsTightening(true)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: maxContentWidth)
                            .padding(.horizontal, horizontalPadding(for: width))

                        if let a = welcome.manifest?.attribution, !a.isEmpty {
                            Text(a)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .allowsTightening(true)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: maxContentWidth)
                                .padding(.horizontal, horizontalPadding(for: width))
                        }
                    }
                    .padding(.vertical, 12)
                    // Lift above home indicator / tab bar, adaptive
                    .padding(.bottom, bottomSafe + 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Keep navigation styling consistent with other tabs, but no title text.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .contentShape(Rectangle())
        .contextMenu { dailyContextMenu }
        .task { await welcome.refreshIfNeeded() }
    }

    private var backgroundImage: some View {
        Group {
            if let img = dailyUIImage {
                // Fill the screen on all devices; some cropping is expected with scaledToFill.
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    // Contain the view in a square of the screen to avoid layout surprises when rotating.
                    .contentShape(Rectangle())
            } else {
                Color(.secondarySystemBackground)
                    .overlay(ProgressView().progressViewStyle(.circular))
            }
        }
    }

    private var dailyUIImage: UIImage? {
        guard let url = welcome.cachedImageFileURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - Layout helpers

    private func responsiveFontSize(for width: CGFloat) -> CGFloat {
        // Scale with safe width; clamp for small/large devices
        let scaled = width * 0.105
        return min(46, max(24, scaled))
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        // A bit more padding on smaller devices, less on large.
        max(16, min(28, width * 0.06))
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
