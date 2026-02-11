// WelcomeSurfaceStore.swift

import Foundation
import Combine

@MainActor
final class WelcomeSurfaceStore: ObservableObject {
    @Published private(set) var manifest: WelcomeManifest? = nil
    @Published private(set) var cachedImageFileURL: URL? = nil

    /// Endpoint read from Info.plist on init.
    private(set) var endpointURL: URL? = nil

    private let fm = FileManager.default

    init() {
        endpointURL = Self.readEndpointURLFromPlist()
        print("WelcomeSurfaceStore.init endpointURL =", endpointURL?.absoluteString ?? "nil")
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
            print("WelcomeSurfaceStore error:", error)
        }
    }

    // MARK: - Private

    private static func readEndpointURLFromPlist() -> URL? {
        func readEndpointString() -> String? {
            // Accept either key to avoid silent mismatch.
            let rawA = Bundle.main.object(forInfoDictionaryKey: "WELCOME_MANIFEST_ENDPOINT") as? String
            let rawB = Bundle.main.object(forInfoDictionaryKey: "WelcomeManifestEndpoint") as? String

            // Prefer the all-caps key if present.
            let raw = (rawA?.isEmpty == false) ? rawA : rawB
            guard var s = raw else { return nil }

            // Common failure modes: newline, leading/trailing spaces, or accidental prefix.
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)

            // If someone pasted "endpointURL = https://..." into plist, strip the prefix.
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
            // best-effort
        }
    }
}
