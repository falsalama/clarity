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

    // Allow views to explicitly flush the cache (e.g. pull-to-refresh)
    func clear() {
        cache.removeAllObjects()
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
            print("Image: nil url (no request)")
            uiImage = nil
            return
        }

        print("Image GET:", url.absoluteString)

        // No stale fallback image
        uiImage = nil

        if let cached = ImageMemoryCache.shared.image(for: url) {
            print("Image: memory cache hit")
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
            print("Image ALT GET:", alt.absoluteString)

            if let cachedAlt = ImageMemoryCache.shared.image(for: alt) {
                print("Image: memory cache hit (alt)")
                uiImage = cachedAlt
                return
            }

            if let img = await fetchAndDownsample(from: alt) {
                ImageMemoryCache.shared.set(img, for: alt)
                uiImage = img
                return
            }
        }

        print("Image: failed (kept placeholder)")
        // keep placeholder
    }

    private func fetchAndDownsample(from url: URL) async -> UIImage? {
        var req = URLRequest(url: url)
        // DEBUG: avoids cached 404/empty responses while you diagnose Release/TestFlight behaviour
        req.cachePolicy = .returnCacheDataElseLoad
        req.timeoutInterval = 20

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let http = resp as? HTTPURLResponse
            let code = http?.statusCode ?? -1
            let mime = http?.mimeType ?? "nil"

            print("Image HTTP:", code, "mime:", mime, "bytes:", data.count)

            guard (200...299).contains(code) else {
                return nil
            }

            let img = downsample(data: data, maxPixelSize: maxPixelSize)
            if img == nil {
                print("Image: downsample/decode failed")
            }
            return img
        } catch {
            print("Image error:", error.localizedDescription)
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
