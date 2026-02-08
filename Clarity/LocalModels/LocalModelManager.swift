//
//  LocalModelManager.swift
//  Clarity
//
//  Manages optional on-device model storage (e.g. Llama .gguf) in Application Support.
//  - Supports: download (URLSession), delete, import via Files (Simulator + device), legacy folder migration.
//  - Validates: minimum file size + basic sanity checks to avoid “HTML/blocked download” being treated as a model.
//

import Foundation
import Combine

@MainActor
final class LocalModelManager: NSObject, ObservableObject {

    enum State: Equatable {
        case notInstalled
        case downloading(progress: Double?)   // 0.0–1.0 if known
        case ready
        case failed(String)
    }

    @Published private(set) var state: State = .notInstalled

    static let shared = LocalModelManager()

    private override init() {
        super.init()
        migrateLegacyDirectoryIfNeeded()
        refreshState()
    }

    // MARK: - Model configuration (single-model, v1)

    private let modelDisplayName = "Llama 3.2 3B Instruct (Q4_K_M)"
    private let modelFileName = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"

    private let downloadURL = URL(
        string: "https://huggingface.co/hugging-quants/Llama-3.2-3B-Instruct-Q4_K_M-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    )!

    // Minimum plausible size (bytes) to reject HTML/403/redirect downloads.
    private let minimumValidSizeBytes: Int64 = 500 * 1024 * 1024 // 500 MB

    // MARK: - Download session

    private var downloadTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        // Ephemeral avoids caches persisting reviewer/device state.
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 60 * 60 // big files
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // MARK: - Paths

    private var appSupportURL: URL {
        // Using url(for:create:) for robustness.
        (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    // Canonical directory (lowercase) — ensure your engine/provider uses the same.
    private var modelsDirectoryURL: URL {
        appSupportURL.appendingPathComponent("models", isDirectory: true)
    }

    // Legacy directory (uppercase) from earlier builds.
    private var legacyModelsDirectoryURL: URL {
        appSupportURL.appendingPathComponent("Models", isDirectory: true)
    }

    private var modelURL: URL {
        modelsDirectoryURL.appendingPathComponent(modelFileName, isDirectory: false)
    }

    // MARK: - Public API (UI)

    var modelNameForUI: String { modelDisplayName }
    var expectedFileNameForUI: String { modelFileName }
    var expectedPathForUI: String { modelURL.path }

    var existsForUI: Bool {
        FileManager.default.fileExists(atPath: modelURL.path)
    }

    var fileSizeBytesForUI: Int64 {
        fileSizeBytes(at: modelURL)
    }

    var isInstalled: Bool {
        guard existsForUI else { return false }
        return fileSizeBytesForUI >= minimumValidSizeBytes
    }

    func refreshStatePublic() {
        refreshState()
    }

    // MARK: - Download

    func startDownload() {
        switch state {
        case .downloading:
            return
        default:
            break
        }

        ensureModelsDirectoryExists()
        state = .downloading(progress: nil)

        // Cancel any previous task.
        downloadTask?.cancel()
        downloadTask = urlSession.downloadTask(with: downloadURL)
        downloadTask?.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        refreshState()
    }

    // MARK: - Import (Simulator + device)

    /// Copies a user-selected .gguf file into Application Support/models/<expected filename>.
    /// This is the simplest way to make Simulator installs work (via Files / drag-drop into Simulator).
    func importModel(from sourceURL: URL) throws {
        ensureModelsDirectoryExists()

        let fm = FileManager.default
        let dest = modelURL

        // Security-scoped access when coming from Files/iCloud providers.
        let secured = sourceURL.startAccessingSecurityScopedResource()
        defer { if secured { sourceURL.stopAccessingSecurityScopedResource() } }

        // Replace atomically where possible.
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }

        // Copy (not move) to avoid mutating the user’s original file.
        try fm.copyItem(at: sourceURL, to: dest)

        try validateModelFile(at: dest)

        state = .ready
    }

    // MARK: - Delete

    func deleteModel() {
        do {
            if FileManager.default.fileExists(atPath: modelURL.path) {
                try FileManager.default.removeItem(at: modelURL)
            }
            state = .notInstalled
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Consumer API (engine/provider)

    func modelPath() throws -> String {
        guard isInstalled else {
            throw NSError(
                domain: "LocalModel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Local model not installed."]
            )
        }
        return modelURL.path
    }

    // MARK: - Helpers

    private func refreshState() {
        if isInstalled {
            state = .ready
        } else {
            state = .notInstalled
        }
    }

    private func ensureModelsDirectoryExists() {
        let dir = modelsDirectoryURL
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)
        if !(exists && isDir.boolValue) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func validateModelFile(at url: URL) throws {
        let size = fileSizeBytes(at: url)
        guard size >= minimumValidSizeBytes else {
            try? FileManager.default.removeItem(at: url)
            throw NSError(
                domain: "LocalModel",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Model file is too small. The download/import was likely blocked or not a .gguf."]
            )
        }

        // Cheap sanity check: “GGUF” header in first 4 bytes.
        // This avoids treating HTML/error pages as models in cases where size check is bypassed.
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let header = try handle.read(upToCount: 4) ?? Data()
        if header.count == 4 {
            let magic = String(bytes: header, encoding: .ascii)
            if magic != "GGUF" {
                // Some files may still be valid, but if it’s not GGUF magic, treat as invalid for this pipeline.
                try? FileManager.default.removeItem(at: url)
                throw NSError(
                    domain: "LocalModel",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Imported file does not look like a GGUF model."]
                )
            }
        }
    }

    // Migrate from legacy "Models" → canonical "models" if needed.
    private func migrateLegacyDirectoryIfNeeded() {
        let fm = FileManager.default
        let legacy = legacyModelsDirectoryURL
        let canonical = modelsDirectoryURL

        var isDir: ObjCBool = false
        let legacyExists = fm.fileExists(atPath: legacy.path, isDirectory: &isDir) && isDir.boolValue

        guard legacyExists else { return }

        ensureModelsDirectoryExists()

        let contents = (try? fm.contentsOfDirectory(at: legacy, includingPropertiesForKeys: nil)) ?? []
        for url in contents where url.pathExtension.lowercased() == "gguf" {
            let dest = canonical.appendingPathComponent(url.lastPathComponent)
            if !fm.fileExists(atPath: dest.path) {
                try? fm.moveItem(at: url, to: dest)
            }
        }

        if let remaining = try? fm.contentsOfDirectory(atPath: legacy.path), remaining.isEmpty {
            try? fm.removeItem(at: legacy)
        }
    }

    private func fileSizeBytes(at url: URL) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func fail(_ message: String) {
        state = .failed(message)
    }
}

// MARK: - URLSessionDownloadDelegate

extension LocalModelManager: URLSessionDownloadDelegate {

    nonisolated func urlSession(_ session: URLSession,
                               downloadTask: URLSessionDownloadTask,
                               didWriteData bytesWritten: Int64,
                               totalBytesWritten: Int64,
                               totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else {
            Task { @MainActor in
                if case .downloading = self.state {
                    self.state = .downloading(progress: nil)
                }
            }
            return
        }

        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            if case .downloading = self.state {
                self.state = .downloading(progress: p)
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                               downloadTask: URLSessionDownloadTask,
                               didFinishDownloadingTo location: URL) {
        Task { @MainActor in
            do {
                self.ensureModelsDirectoryExists()

                let fm = FileManager.default
                let dest = self.modelURL

                if fm.fileExists(atPath: dest.path) {
                    try fm.removeItem(at: dest)
                }

                // Move temp download into place.
                try fm.moveItem(at: location, to: dest)

                // Validate before marking ready.
                try self.validateModelFile(at: dest)

                self.state = .ready
                self.downloadTask = nil
            } catch {
                self.downloadTask = nil
                self.fail(error.localizedDescription)
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                               task: URLSessionTask,
                               didCompleteWithError error: Error?) {
        guard let error else { return }

        Task { @MainActor in
            self.downloadTask = nil

            // Ignore cancellation as an “error” state.
            if (error as NSError).code == NSURLErrorCancelled {
                self.refreshState()
                return
            }

            self.fail(error.localizedDescription)
        }
    }
}
