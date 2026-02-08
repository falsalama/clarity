//
//  LocalModelManager.swift
//  Clarity
//
//  Manages optional on-device model downloads (e.g. Llama GGUF) in Application Support.
//

import Foundation
import Combine

@MainActor
final class LocalModelManager: ObservableObject {

    enum State: Equatable {
        case notInstalled
        case downloading
        case ready
        case failed(String)
    }

    @Published private(set) var state: State = .notInstalled

    static let shared = LocalModelManager()

    private init() {
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

    // MARK: - Paths

    private var modelsDirectoryURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("Models", isDirectory: true)
    }

    private var modelURL: URL {
        modelsDirectoryURL.appendingPathComponent(modelFileName)
    }

    // MARK: - Public API

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

    func startDownload() {
        guard state != .downloading else { return }

        ensureModelsDirectoryExists()
        state = .downloading

        let destinationURL = modelURL

        let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempURL, _, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.state = .failed(error.localizedDescription)
                    return
                }

                guard let tempURL else {
                    self.state = .failed("Download failed (no temp file).")
                    return
                }

                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }

                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)

                    let size = self.fileSizeBytes(at: destinationURL)
                    guard size >= self.minimumValidSizeBytes else {
                        try? FileManager.default.removeItem(at: destinationURL)
                        self.state = .failed("Downloaded file is too small. The download was likely blocked or redirected.")
                        return
                    }

                    self.state = .ready
                } catch {
                    self.state = .failed(error.localizedDescription)
                }
            }
        }

        task.resume()
    }

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
        state = isInstalled ? .ready : .notInstalled
    }

    private func ensureModelsDirectoryExists() {
        let dir = modelsDirectoryURL
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func fileSizeBytes(at url: URL) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    }
}

