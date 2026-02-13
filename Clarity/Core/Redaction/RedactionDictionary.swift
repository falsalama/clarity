// RedactionDictionary.swift
import Foundation
import Combine

@MainActor
final class RedactionDictionary: ObservableObject {
    @Published var tokens: [String] = []

    private let fm = FileManager.default
    private let filename = "redaction_dictionary.json"

    init() {
        load()
    }

    func add(_ token: String) {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        guard !tokens.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) else { return }

        tokens.append(t)
        tokens.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        save()
    }

    func remove(at offsets: IndexSet) {
        for idx in offsets.sorted(by: >) {
            guard tokens.indices.contains(idx) else { continue }
            tokens.remove(at: idx)
        }
        save()
    }

    func wipe() {
        tokens = []
        save()
    }

    // MARK: - Disk

    private func load() {
        do {
            let url = try fileURL()
            guard fm.fileExists(atPath: url.path) else {
                tokens = []
                return
            }
            let data = try Data(contentsOf: url)
            tokens = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        } catch {
            tokens = []
        }
    }

    private func save() {
        do {
            let url = try fileURL()
            let data = try JSONEncoder().encode(tokens)
            try data.write(to: url, options: [.atomic])
        } catch {
            // silent by design
        }
    }

    private func fileURL() throws -> URL {
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("Clarity", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(filename)
    }
}

