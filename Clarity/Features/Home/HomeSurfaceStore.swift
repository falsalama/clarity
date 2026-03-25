import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class HomeSurfaceStore: ObservableObject {
    @Published private(set) var manifest: WelcomeManifest? = nil
    @Published private(set) var cachedImageFileURL: URL? = nil

    private(set) var endpointURL: URL? = nil

    private let fm = FileManager.default
    private var observers: [NSObjectProtocol] = []

    private let lastFetchKey = "home_surface_last_fetch_at"
    private let currentSequenceKey = "home_surface_current_sequence_index"
    private let lastSeenDayKey = "home_surface_last_seen_day_key"
    private let lastAdvancedDayKey = "home_surface_last_advanced_day_key"
    private let currentImageURLKey = "home_surface_current_image_url"
    private let prefetchedImageURLKey = "home_surface_prefetched_image_url"

    init() {
        endpointURL = Self.readEndpointURLFromPlist()
        loadCached()
    }

    // MARK: - Public

    func refreshNow(forceImageReload: Bool = false) async {
        advanceSequenceIfNeededForNewDay()

        guard let requestURL = endpointURLForCurrentSequence() else { return }

        do {
            var req = URLRequest(url: requestURL)
            req.cachePolicy = .useProtocolCachePolicy

            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let newManifest = try JSONDecoder().decode(WelcomeManifest.self, from: data)

            // Persist the server-normalized current sequence so local state stays aligned
            UserDefaults.standard.set(newManifest.sequenceIndex, forKey: currentSequenceKey)

            if forceImageReload {
                clearCurrentImage()
                clearPrefetchedImage()
            }

            let resolvedImageURL = await resolveCurrentImage(for: newManifest)
            manifest = newManifest
            cachedImageFileURL = resolvedImageURL

            try persistManifest(newManifest)
            setLastFetchNow()

            await prefetchNextImageIfNeeded(for: newManifest)
        } catch {
            // best-effort silent failure
        }
    }

    func refreshIfStale(maxAgeSeconds: TimeInterval) async {
        if manifest == nil {
            await refreshNow()
            return
        }

        guard let last = lastFetchAt() else {
            await refreshNow()
            return
        }

        if Date().timeIntervalSince(last) > maxAgeSeconds {
            await refreshNow()
        }
    }

    func refreshIfNeededForToday() async {
        await refreshIfStale(maxAgeSeconds: 6 * 60 * 60)
    }

    func forceRefresh() async {
        await refreshNow(forceImageReload: true)
    }

    func markCurrentWelcomeSeen() {
        UserDefaults.standard.set(localDayKey(), forKey: lastSeenDayKey)
    }

    // MARK: - Lifecycle hooks

    func startDailyAutoRefresh() {
        installObserversIfNeeded()
    }

    func stopDailyAutoRefresh() {
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
        observers.removeAll()
    }

    // MARK: - Plist

    private static func readEndpointURLFromPlist() -> URL? {
        let keys = [
            "HOME_SURFACE_ENDPOINT",
            "HomeSurfaceEndpoint",
            "WELCOME_MANIFEST_ENDPOINT",
            "WelcomeManifestEndpoint"
        ]

        for key in keys {
            if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
               raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {

                let cleaned = raw
                    .replacingOccurrences(of: "endpointURL =", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let url = URL(string: cleaned) {
                    return url
                }
            }
        }
        return nil
    }

    // MARK: - Paths

    private func baseDir() -> URL {
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("HomeSurface", isDirectory: true)

        if fm.fileExists(atPath: dir.path) == false {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir
    }

    private func manifestPath() -> URL {
        baseDir().appendingPathComponent("manifest.json")
    }

    private func currentImagePath() -> URL {
        baseDir().appendingPathComponent("image-current.bin")
    }

    private func prefetchedImagePath() -> URL {
        baseDir().appendingPathComponent("image-prefetch.bin")
    }

    // MARK: - Load / persist

    private func loadCached() {
        guard
            let data = try? Data(contentsOf: manifestPath()),
            let cached = try? JSONDecoder().decode(WelcomeManifest.self, from: data)
        else {
            manifest = nil
            cachedImageFileURL = nil
            return
        }

        manifest = cached

        let currentPath = currentImagePath()
        cachedImageFileURL = fm.fileExists(atPath: currentPath.path) ? currentPath : nil
    }

    private func persistManifest(_ manifest: WelcomeManifest) throws {
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: manifestPath(), options: [.atomic])
    }

    // MARK: - Endpoint

    private func endpointURLForCurrentSequence() -> URL? {
        guard let endpointURL else { return nil }

        var comps = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false)
        var items = comps?.queryItems ?? []
        items.removeAll { $0.name == "index" }
        items.append(URLQueryItem(name: "index", value: String(currentSequenceIndexToRequest())))
        comps?.queryItems = items

        return comps?.url
    }

private func currentSequenceIndexToRequest() -> Int {
    max(0, UserDefaults.standard.integer(forKey: currentSequenceKey))
}

private func advanceSequenceIfNeededForNewDay() {
    let defaults = UserDefaults.standard
    let today = localDayKey()

    let lastSeen = defaults.string(forKey: lastSeenDayKey) ?? ""
    let lastAdvanced = defaults.string(forKey: lastAdvancedDayKey) ?? ""

    // First ever run: stay on current sequence.
    guard !lastSeen.isEmpty else { return }

    // Already saw welcome today: do not advance.
    guard lastSeen != today else { return }

    // Already advanced once for this day: do not advance again.
    guard lastAdvanced != today else { return }

    let next = currentSequenceIndexToRequest() + 1
    defaults.set(next, forKey: currentSequenceKey)
    defaults.set(today, forKey: lastAdvancedDayKey)
}

private func localDayKey() -> String {
    let f = DateFormatter()
    f.calendar = Calendar.current
    f.timeZone = .current
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
}


    // MARK: - Image resolution

    private func resolveCurrentImage(for manifest: WelcomeManifest) async -> URL? {
        guard let urlString = manifest.imageURL, let remoteURL = URL(string: urlString) else {
            clearCurrentImage()
            return nil
        }

        let currentPath = currentImagePath()
        let currentCachedURL = UserDefaults.standard.string(forKey: currentImageURLKey)
        let prefetchedURL = UserDefaults.standard.string(forKey: prefetchedImageURLKey)

        if currentCachedURL == urlString, fm.fileExists(atPath: currentPath.path) {
            return currentPath
        }

        if prefetchedURL == urlString, fm.fileExists(atPath: prefetchedImagePath().path) {
            promotePrefetchedImageIfPossible(for: urlString)
            return fm.fileExists(atPath: currentPath.path) ? currentPath : nil
        }

        guard let data = await downloadImageData(from: remoteURL) else {
            return nil
        }

        do {
            try data.write(to: currentPath, options: [.atomic])
            UserDefaults.standard.set(urlString, forKey: currentImageURLKey)
            return currentPath
        } catch {
            return nil
        }
    }

    private func prefetchNextImageIfNeeded(for manifest: WelcomeManifest) async {
        guard let nextURLString = manifest.nextImageURL, let remoteURL = URL(string: nextURLString) else {
            clearPrefetchedImage()
            return
        }

        let currentURL = UserDefaults.standard.string(forKey: currentImageURLKey)
        let prefetchedURL = UserDefaults.standard.string(forKey: prefetchedImageURLKey)
        let prefetchPath = prefetchedImagePath()

        if nextURLString == currentURL {
            clearPrefetchedImage()
            return
        }

        if prefetchedURL == nextURLString, fm.fileExists(atPath: prefetchPath.path) {
            return
        }

        guard let data = await downloadImageData(from: remoteURL) else {
            return
        }

        do {
            try data.write(to: prefetchPath, options: [.atomic])
            UserDefaults.standard.set(nextURLString, forKey: prefetchedImageURLKey)
        } catch {
            // silent
        }
    }

    private func promotePrefetchedImageIfPossible(for urlString: String) {
        let prefetchPath = prefetchedImagePath()
        let currentPath = currentImagePath()
        let prefetchedURL = UserDefaults.standard.string(forKey: prefetchedImageURLKey)

        guard prefetchedURL == urlString, fm.fileExists(atPath: prefetchPath.path) else {
            clearCurrentImage()
            cachedImageFileURL = nil
            return
        }

        try? fm.removeItem(at: currentPath)
        try? fm.moveItem(at: prefetchPath, to: currentPath)

        UserDefaults.standard.set(urlString, forKey: currentImageURLKey)
        UserDefaults.standard.removeObject(forKey: prefetchedImageURLKey)
        cachedImageFileURL = fm.fileExists(atPath: currentPath.path) ? currentPath : nil
    }

    private func clearCurrentImage() {
        try? fm.removeItem(at: currentImagePath())
        UserDefaults.standard.removeObject(forKey: currentImageURLKey)
        cachedImageFileURL = nil
    }

    private func clearPrefetchedImage() {
        try? fm.removeItem(at: prefetchedImagePath())
        UserDefaults.standard.removeObject(forKey: prefetchedImageURLKey)
    }

    private func downloadImageData(from url: URL) async -> Data? {
        do {
            var req = URLRequest(url: url)
            req.cachePolicy = .useProtocolCachePolicy

            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return data
        } catch {
            return nil
        }
    }

    // MARK: - Observers

    private func installObserversIfNeeded() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default

        let dayChange = center.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refreshIfStale(maxAgeSeconds: 6 * 60 * 60)
            }
        }

        observers.append(dayChange)
    }

    // MARK: - Last fetch

    private func lastFetchAt() -> Date? {
        let t = UserDefaults.standard.double(forKey: lastFetchKey)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    private func setLastFetchNow() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFetchKey)
    }
}
