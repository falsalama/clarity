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
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Foreground content layer
            GeometryReader { geo in
                let bottomSafe = geo.safeAreaInsets.bottom
                let tabBarHeight: CGFloat = 49

                VStack {
                    Spacer()

                    VStack(spacing: 8) {
                        Text(welcome.manifest?.message ?? "Welcome")
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .italic()
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .minimumScaleFactor(0.72)
                            .allowsTightening(true)

                        if let a = welcome.manifest?.attribution, !a.isEmpty {
                            Text(a)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .allowsTightening(true)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    // Lift above tab bar + home indicator
                    .padding(.bottom, bottomSafe + tabBarHeight + 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Keep navigation styling consistent with other tabs, but no title text.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // Optional: makes nav bar background transparent so the image shows through.
        .toolbarBackground(.hidden, for: .navigationBar)
        // Your share/save menu still works (long-press anywhere).
        .contentShape(Rectangle())
        .contextMenu { dailyContextMenu }
        .task { await welcome.refreshIfNeeded() }
    }

    private var backgroundImage: some View {
        Group {
            if let img = dailyUIImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
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

