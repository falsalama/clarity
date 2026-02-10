import Foundation

enum FileStore {

    // MARK: - Stored path conventions
    // Stored audio paths may be:
    // - absolute POSIX: "/var/mobile/.../clarity_x.caf" (legacy)
    // - file URL string: "file:///var/mobile/.../clarity_x.caf" (legacy variant)
    // - relative to Application Support: "Clarity/audio/clarity_x.caf" (preferred)

    static func storedAudioPath(forFilename filename: String) -> String {
        "Clarity/audio/\(filename)"
    }

    // MARK: - Directories

    static func applicationSupportURL(create: Bool) -> URL? {
        try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: create
        )
    }

    static func audioDirectoryURL(create: Bool) -> URL? {
        guard let appSupport = applicationSupportURL(create: create) else { return nil }

        // Canonical: <App Support>/Clarity/audio
        let dir = appSupport
            .appendingPathComponent("Clarity", isDirectory: true)
            .appendingPathComponent("audio", isDirectory: true)

        if create {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Resolution

    static func resolveStoredAudioURL(from storedPath: String?) -> URL? {
        guard let storedPath, !storedPath.isEmpty else { return nil }

        // Handle "file://..." strings (legacy variant)
        if storedPath.hasPrefix("file://") {
            if let url = URL(string: storedPath) {
                return url
            }
            // Fallback: strip scheme and treat remainder as a path
            let stripped = storedPath.replacingOccurrences(of: "file://", with: "")
            if stripped.hasPrefix("/") {
                return URL(fileURLWithPath: stripped)
            }
        }

        // Absolute POSIX path (legacy)
        if storedPath.hasPrefix("/") {
            return URL(fileURLWithPath: storedPath)
        }

        // Relative to Application Support (preferred)
        guard let appSupport = applicationSupportURL(create: false) else { return nil }
        return appSupport.appendingPathComponent(storedPath, isDirectory: false)
    }

    static func existingAudioURL(from storedPath: String?) -> URL? {
        let fm = FileManager.default

        // Primary: resolve directly then check existence
        if let url = resolveStoredAudioURL(from: storedPath),
           fm.fileExists(atPath: url.path) {
            return url
        }

        // Fallback: search by filename inside <App Support>/Clarity/audio
        guard let storedPath, !storedPath.isEmpty else { return nil }

        let filename: String = {
            if storedPath.hasPrefix("file://") {
                // Try URL parsing first; if it fails, strip scheme and parse as path.
                if let url = URL(string: storedPath) {
                    return url.lastPathComponent
                }
                let stripped = storedPath.replacingOccurrences(of: "file://", with: "")
                return URL(fileURLWithPath: stripped).lastPathComponent
            }

            if storedPath.hasPrefix("/") {
                return URL(fileURLWithPath: storedPath).lastPathComponent
            }

            // relative "Clarity/audio/<file>" or similar
            return URL(fileURLWithPath: storedPath).lastPathComponent
        }()

        guard !filename.isEmpty,
              let audioDir = audioDirectoryURL(create: false) else { return nil }

        let candidate = audioDir.appendingPathComponent(filename, isDirectory: false)
        return fm.fileExists(atPath: candidate.path) ? candidate : nil
    }
    static func normalisedStoredAudioPath(from storedPath: String?) -> String? {
        guard let storedPath, !storedPath.isEmpty else { return nil }

        // Already preferred format
        if storedPath.hasPrefix("Clarity/audio/") { return nil }

        // If we can resolve it to an existing file, rewrite to preferred relative path
        guard let url = existingAudioURL(from: storedPath) else { return nil }
        let filename = url.lastPathComponent
        guard !filename.isEmpty else { return nil }

        return storedAudioPath(forFilename: filename)
    }

    // MARK: - Deletes

    static func removeAudioIfExists(storedPath: String?) {
        guard let url = existingAudioURL(from: storedPath) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // Compatibility: some call sites might still pass absolute paths
    static func removeIfExists(atPath path: String?) {
        guard let path, !path.isEmpty else { return }

        let fm = FileManager.default
        let url: URL

        if path.hasPrefix("file://") {
            if let u = URL(string: path) {
                url = u
            } else {
                let stripped = path.replacingOccurrences(of: "file://", with: "")
                url = URL(fileURLWithPath: stripped)
            }
        } else if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            // treat as relative
            guard let appSupport = applicationSupportURL(create: false) else { return }
            url = appSupport.appendingPathComponent(path, isDirectory: false)
        }

        guard fm.fileExists(atPath: url.path) else { return }
        try? fm.removeItem(at: url)
    }
}

