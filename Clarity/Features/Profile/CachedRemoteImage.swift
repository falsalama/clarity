import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import ImageIO
import CryptoKit

// MARK: - Memory cache (URL+px key)

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.totalCostLimit = 32 * 1024 * 1024
        return c
    }()

    private init() {}

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

// MARK: - Disk cache (per URL)

enum ImageDiskCache {
    static func url(for url: URL) -> URL? {
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let name = sha256(url.absoluteString) + ".bin"
        return dir.appendingPathComponent("calendar_image_cache", isDirectory: true)
            .appendingPathComponent(name)
    }

    static func ensureDir() {
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let folder = dir.appendingPathComponent("calendar_image_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    static func loadData(for url: URL) -> Data? {
        ensureDir()
        guard let file = self.url(for: url) else { return nil }
        return try? Data(contentsOf: file)
    }

    static func saveData(_ data: Data, for url: URL) {
        ensureDir()
        guard let file = self.url(for: url) else { return }
        try? data.write(to: file, options: [.atomic])
    }

    private static func sha256(_ s: String) -> String {
        let digest = SHA256.hash(data: Data(s.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - View

struct CachedRemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var maxPixelSize: CGFloat = 256

    @State private var uiImage: UIImage? = nil
    @State private var didFail = false

    private var key: String? {
        guard let url else { return nil }
        return "\(url.absoluteString)|px=\(Int(maxPixelSize))"
    }

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.gray.opacity(0.10)
            }
        }
        .task(id: key) { await load() }
    }

    @MainActor
    private func load() async {
        guard let url, let key else { return }
        guard !didFail else { return }

        if let cached = ImageMemoryCache.shared.image(forKey: key) {
            uiImage = cached
            return
        }

        // Disk cache stores original data per URL (not px). We downsample per request.
        if let data = ImageDiskCache.loadData(for: url),
           let img = downsample(data: data, maxPixelSize: maxPixelSize) {
            ImageMemoryCache.shared.set(img, forKey: key)
            uiImage = img
            return
        }

        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 20

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("Image HTTP \(http.statusCode):", url.absoluteString)
                didFail = true
                return
            }

            ImageDiskCache.saveData(data, for: url)

            if let img = downsample(data: data, maxPixelSize: maxPixelSize) {
                ImageMemoryCache.shared.set(img, forKey: key)
                uiImage = img
            } else {
                print("Downsample failed:", url.absoluteString)
                didFail = true
            }
        } catch {
            print("Image load error:", error, url.absoluteString)
            didFail = true
        }
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
