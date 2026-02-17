// HomeSurfaceStore.swift

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
    private var midnightTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    private let lastFetchKey = "home_surface_last_fetch_at"

    init() {
        endpointURL = Self.readEndpointURLFromPlist()
        loadCached()
        // Do not start timers/observers automatically here.
        // AppShellView controls start/stop to avoid duplicate observers.
    }

    // MARK: - Public

    /// Always fetch the manifest (small). Only download image if URL changed or missing locally.
    func refreshNow() async {
        guard let endpointURL else { return }

        do {
            var req = URLRequest(url: endpointURL)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let oldImageURL = manifest?.imageURL
            let oldDateKey = manifest?.dateKey

            let newManifest = try JSONDecoder().decode(WelcomeManifest.self, from: data)
            manifest = newManifest
            try persistManifest(data)
            setLastFetchNow()

            // Re-download image if:
            // - the URL changed, OR
            // - it's a new day (dateKey changed), OR
            // - we don't actually have a cached image file.
            if let urlString = newManifest.imageURL,
               let imageURL = URL(string: urlString) {

                let hasCachedImage = cachedImageFileURL != nil && fm.fileExists(atPath: imagePath().path)
                let imageChanged = (oldImageURL != urlString)
                let dateChanged = (oldDateKey != newManifest.dateKey)

                if imageChanged || dateChanged || !hasCachedImage {
                    await fetchAndCacheImage(from: imageURL)
                }
            } else {
                // If server removed imageURL, keep cached image as-is (best UX).
            }


            // Note: message changes will reflect immediately because manifest is updated.
            _ = oldDateKey // retained for clarity; dateKey is used by refreshIfNeededForToday()
        } catch {
            // best-effort silent failure
        }
    }

    func refreshIfStale(maxAgeSeconds: TimeInterval) async {
        if manifest == nil { await refreshNow(); return }
        guard let last = lastFetchAt() else { await refreshNow(); return }
        if Date().timeIntervalSince(last) > maxAgeSeconds {
            await refreshNow()
        }
    }

    func refreshIfNeededForToday() async {
        guard needsRefreshForToday() else { return }
        await refreshNow()
    }

    // MARK: - Auto refresh

    func startDailyAutoRefresh() {
        installObserversIfNeeded()
        scheduleNextMidnightTimer()
    }

    func stopDailyAutoRefresh() {
        midnightTimer?.invalidate()
        midnightTimer = nil

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

    // MARK: - Cache paths

    private func baseDir() -> URL {
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let newDir = appSupport.appendingPathComponent("HomeSurface", isDirectory: true)
        let oldDir = appSupport.appendingPathComponent("WelcomeSurface", isDirectory: true)

        if fm.fileExists(atPath: newDir.path) == false {
            if fm.fileExists(atPath: oldDir.path) { return oldDir }
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
            var req = URLRequest(url: url)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            let (data, response) = try await URLSession.shared.data(for: req)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            let path = imagePath()
            try data.write(to: path, options: [.atomic])
            cachedImageFileURL = path
        } catch {
            // silent
        }
    }

    // MARK: - Today / midnight

    private func needsRefreshForToday() -> Bool {
        guard let cached = manifest else { return true }
        return cached.dateKey != todayDateKey()
    }

    private func todayDateKey() -> String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar.current
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private func nextLocalMidnight() -> Date {
        let cal = Calendar.current
        let now = Date()
        let comps = DateComponents(hour: 0, minute: 0, second: 5)
        return cal.nextDate(after: now, matching: comps, matchingPolicy: .nextTime)
            ?? now.addingTimeInterval(24 * 60 * 60)
    }

    private func scheduleNextMidnightTimer() {
        midnightTimer?.invalidate()
        midnightTimer = nil

        let fireDate = nextLocalMidnight()
        let interval = max(1.0, fireDate.timeIntervalSinceNow)

        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refreshIfNeededForToday()
                self.scheduleNextMidnightTimer()
            }
        }
    }

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
                await self.refreshIfNeededForToday()
                self.scheduleNextMidnightTimer()
            }
        }
        observers.append(dayChange)

        // NOTE: foreground refresh is driven by AppShellView (scenePhase),
        // so we do not add UIApplication observers here (avoids duplication).
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

