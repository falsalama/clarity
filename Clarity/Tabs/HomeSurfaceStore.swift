// HomeSurfaceStore.swift

import Foundation
import Combine

@MainActor
final class HomeSurfaceStore: ObservableObject {
    @Published private(set) var manifest: WelcomeManifest? = nil
    @Published private(set) var cachedImageFileURL: URL? = nil

    /// Endpoint read from Info.plist on init.
    private(set) var endpointURL: URL? = nil

    private let fm = FileManager.default

    init() {
        endpointURL = Self.readEndpointURLFromPlist()
        loadCached()
    }

    func refreshIfNeeded() async {
        guard let endpointURL else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: endpointURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let newManifest = try JSONDecoder().decode(WelcomeManifest.self, from: data)
            manifest = newManifest
            try persistManifest(data)

            if let urlString = newManifest.imageURL,
               let imageURL = URL(string: urlString) {
                await fetchAndCacheImage(from: imageURL)
            }
        } catch {
            // best-effort
        }
    }

    // MARK: - Private

    private static func readEndpointURLFromPlist() -> URL? {
        func readEndpointString() -> String? {
            // New preferred keys
            let rawA = Bundle.main.object(forInfoDictionaryKey: "HOME_SURFACE_ENDPOINT") as? String
            let rawB = Bundle.main.object(forInfoDictionaryKey: "HomeSurfaceEndpoint") as? String

            // Backward-compatible with previous welcome keys
            let rawC = Bundle.main.object(forInfoDictionaryKey: "WELCOME_MANIFEST_ENDPOINT") as? String
            let rawD = Bundle.main.object(forInfoDictionaryKey: "WelcomeManifestEndpoint") as? String

            // Priority: new keys first, then old
            let raw = [rawA, rawB, rawC, rawD].first { ($0?.isEmpty == false) }

            guard var s = raw ?? nil else { return nil }
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)

            if let range = s.range(of: "endpointURL =") {
                s = String(s[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return s.isEmpty ? nil : s
        }

        guard let urlString = readEndpointString(),
              let url = URL(string: urlString) else {
            return nil
        }
        return url
    }

    // Prefer the new directory, but fall back to the old welcome directory if needed.
    private func baseDir() -> URL {
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let newDir = appSupport.appendingPathComponent("HomeSurface", isDirectory: true)
        let oldDir = appSupport.appendingPathComponent("WelcomeSurface", isDirectory: true)

        if fm.fileExists(atPath: newDir.path) == false {
            // If old exists and new doesn't, use old (no migration step needed to read)
            if fm.fileExists(atPath: oldDir.path) {
                return oldDir
            }
            try? fm.createDirectory(at: newDir, withIntermediateDirectories: true)
        }
        return newDir
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
            // best-effort
        }
    }
}
