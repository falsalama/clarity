import SwiftUI
import UIKit

struct WelcomeOverlayView: View {
    @EnvironmentObject private var store: WelcomeSurfaceStore

    let opacity: Double

    var body: some View {
        ZStack {
            // Background: image if cached, otherwise plain system background
            if let fileURL = store.cachedImageFileURL,
               let uiImage = UIImage(contentsOfFile: fileURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }

            VStack(spacing: 14) {
                Text(store.manifest?.message ?? "Welcome")
                    .font(.system(size: 52, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(0.85)

                // Optional attribution, kept minimal
                if let a = store.manifest?.attribution, !a.isEmpty {
                    Text(a)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .opacity(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(opacity)
        .allowsHitTesting(true)
    }
}

