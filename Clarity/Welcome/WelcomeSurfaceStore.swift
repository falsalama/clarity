import Foundation
import Combine
import SwiftUI


@MainActor
final class WelcomeSurfaceStore: ObservableObject {
    @Published private(set) var manifest: WelcomeManifest? = nil
    @Published private(set) var cachedImageFileURL: URL? = nil

    /// Optional endpoint (wire from Info.plist in AppShellView later).
    var endpointURL: URL? = nil

    private let fm = FileManager.default

    init(endpointURL: URL? = nil) {
        self.endpointURL = endpointURL
        loadCached()
    }

    // MARK: - Public

    func refreshIfNeeded() async {
        guard let endpointURL else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: endpointURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let newManifest = try JSONDecoder().decode(WelcomeManifest.self, from: data)
            manifest = newManifest
            try persistManifest(data)

            if let urlString = newManifest.imageURL, let imageURL = URL(string: urlString) {
                await fetchAndCacheImage(from: imageURL)
            }
        } catch {
            // silent: offline-first
        }
    }

    // MARK: - Private

    private func baseDir() -> URL {
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("WelcomeSurface", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func manifestPath() -> URL {
        baseDir().appendingPathComponent("manifest.json")
    }

    private func imagePath() -> URL {
        baseDir().appendingPathComponent("image.bin")
    }

    private func loadCached() {
        if let data = try? Data(contentsOf: manifestPath()),
           let cached = try? JSONDecoder().decode(WelcomeManifest.self, from: data) {
            manifest = cached
        }

        let img = imagePath()
        if fm.fileExists(atPath: img.path) {
            cachedImageFileURL = img
        }
    }

    private func persistManifest(_ data: Data) throws {
        try data.write(to: manifestPath(), options: [.atomic])
    }

    private func fetchAndCacheImage(from url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let path = imagePath()
            try data.write(to: path, options: [.atomic])
            cachedImageFileURL = path
        } catch {
            // silent
        }
    }
}

