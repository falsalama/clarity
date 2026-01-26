import Foundation
import Combine

struct ClarityCapsule: Codable {
    var version: Int = 1
    var updatedAt: String = ISO8601DateFormatter().string(from: Date())

    // Abstracted only (no transcripts, no identities)
    var preferences: [String: String] = [:]
    var conditions: [String: String] = [:]
    var notes: [String] = []
}

@MainActor
final class CapsuleStore: ObservableObject {
    @Published private(set) var capsule: ClarityCapsule = ClarityCapsule()

    private let fm = FileManager.default

    init() {
        do {
            self.capsule = try loadFromDisk()
        } catch {
            self.capsule = ClarityCapsule()
        }
    }

    // MARK: - Public API

    func setPreference(key: String, value: String) {
        capsule.preferences[key] = value
        persist()
    }

    func removePreference(key: String) {
        capsule.preferences.removeValue(forKey: key)
        persist()
    }

    func setCondition(key: String, value: String) {
        capsule.conditions[key] = value
        persist()
    }

    func removeCondition(key: String) {
        capsule.conditions.removeValue(forKey: key)
        persist()
    }

    func addNote(_ note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        capsule.notes.append(trimmed)
        persist()
    }

    func removeNote(at offsets: IndexSet) {
        // Keep store independent of SwiftUI helpers.
        for i in offsets.sorted(by: >) {
            guard capsule.notes.indices.contains(i) else { continue }
            capsule.notes.remove(at: i)
        }
        persist()
    }

    func wipe() {
        capsule = ClarityCapsule()
        do { try wipeFromDisk() } catch { /* do not crash */ }
    }

    // MARK: - Disk

    private func persist() {
        do { try saveToDisk(capsule) } catch { /* do not crash */ }
    }

    private func loadFromDisk() throws -> ClarityCapsule {
        let url = try capsuleURL()
        guard fm.fileExists(atPath: url.path) else { return ClarityCapsule() }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ClarityCapsule.self, from: data)
    }

    private func saveToDisk(_ capsule: ClarityCapsule) throws {
        let url = try capsuleURL()
        var c = capsule
        c.updatedAt = ISO8601DateFormatter().string(from: Date())
        let data = try JSONEncoder().encode(c)
        try data.write(to: url, options: [.atomic])
    }

    private func wipeFromDisk() throws {
        let url = try capsuleURL()
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }

    private func capsuleURL() throws -> URL {
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("Clarity", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("capsule.json")
    }
}

