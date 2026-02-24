import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - In-memory image cache (simple, app-wide)

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()

    private let cache: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.totalCostLimit = 24 * 1024 * 1024 // ~24MB
        return c
    }()

    private init() {}

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

// MARK: - CachedRemoteImage

struct CachedRemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    @State private var uiImage: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.gray.opacity(0.12)
            }
        }
        .task(id: url) { await load() }
    }

    @MainActor
    private func load() async {
        guard let url else { return }

        if let cached = ImageMemoryCache.shared.image(for: url) {
            uiImage = cached
            return
        }

        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                ImageMemoryCache.shared.set(img, for: url)
                uiImage = img
            }
        } catch {
            // keep placeholder
        }
    }
}
