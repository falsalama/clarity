import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif
import ImageIO

// MARK: - In-memory image cache (simple, app-wide)

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()

    private let cache: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.totalCostLimit = 32 * 1024 * 1024 // ~32MB
        return c
    }()

    private init() {}

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

// MARK: - CachedRemoteImage

struct CachedRemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var maxPixelSize: CGFloat = 256

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

                if isLoading {
                    ProgressView()
                }
            }
        }
        // iOS 17+ onChange signature (no deprecation warning)
        .onChange(of: url) {
            uiImage = nil
            isLoading = false
        }
        .task(id: url) { await load() }
    }

    @MainActor
    private func load() async {
        guard let url else {
            uiImage = nil
            return
        }

        // No stale fallback image
        uiImage = nil

        if let cached = ImageMemoryCache.shared.image(for: url) {
            uiImage = cached
            return
        }

        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // 1) Try the given URL
        if let img = await fetchAndDownsample(from: url) {
            ImageMemoryCache.shared.set(img, for: url)
            uiImage = img
            return
        }

        // 2) If it failed, try the same filename under /category/
        if let alt = alternateCategoryURL(from: url), alt != url {
            if let cachedAlt = ImageMemoryCache.shared.image(for: alt) {
                uiImage = cachedAlt
                return
            }

            if let img = await fetchAndDownsample(from: alt) {
                ImageMemoryCache.shared.set(img, for: alt)
                uiImage = img
                return
            }
        }

        // keep placeholder
    }

    private func fetchAndDownsample(from url: URL) async -> UIImage? {
        var req = URLRequest(url: url)
        req.cachePolicy = .returnCacheDataElseLoad
        req.timeoutInterval = 20

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return downsample(data: data, maxPixelSize: maxPixelSize)
        } catch {
            return nil
        }
    }

    /// If current URL is .../calendar_images/<name>.jpg
    /// return .../calendar_images/category/<name>.jpg
    private func alternateCategoryURL(from url: URL) -> URL? {
        let filename = url.lastPathComponent
        guard !filename.isEmpty else { return nil }

        // Already points at category folder?
        if url.path.contains("/category/") { return nil }

        // Strip last path component, append "category/<filename>"
        var base = url
        base.deleteLastPathComponent()
        let alt = base.appendingPathComponent("category").appendingPathComponent(filename)

        // Preserve query (e.g. ?v=1)
        var comps = URLComponents(url: alt, resolvingAgainstBaseURL: false)
        if let orig = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let q = orig.query, !q.isEmpty {
            comps?.percentEncodedQuery = q
        }
        return comps?.url
    }

    private func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let srcOpts: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let src = CGImageSourceCreateWithData(data as CFData, srcOpts as CFDictionary) else { return nil }

        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize)
        ]

        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }
}
