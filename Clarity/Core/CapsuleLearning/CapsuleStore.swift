// CapsuleStore.swift
import Foundation
import Combine
import os.log

@MainActor
final class CapsuleStore: ObservableObject {
    @Published private(set) var capsule: CapsuleModel = .empty()

    private let fm = FileManager.default
    private let log = Logger(subsystem: "Clarity", category: "CapsuleStore")

    // Bounds for open-ended extras
    private let extrasMaxItems = 34
    private let extrasKeyMax = 64
    private let extrasValueMax = 128

    init() {
        do {
            let loaded = try loadFromDisk()
            let migrated = migrateCapsuleIfNeeded(loaded)
            self.capsule = migrated.capsule
            if migrated.didChange {
                persist()
            }
        } catch {
            self.capsule = .empty()
        }
    }

    // MARK: - Public API (typed)

    func setPseudonym(_ value: String) {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        capsule.preferences.pseudonym = v.isEmpty ? nil : v
        capsule.updatedAt = Date()
        persist()
    }

    func setPreferences(_ prefs: CapsulePreferences) {
        capsule.preferences = prefs
        capsule.updatedAt = Date()
        persist()
    }

    func setLearningEnabled(_ enabled: Bool) {
        capsule.learningEnabled = enabled
        capsule.updatedAt = Date()
        persist()
    }

    func wipe() {
        capsule = .empty()
        do { try wipeFromDisk() } catch {
            log.error("wipeFromDisk failed: \(String(describing: error), privacy: .private)")
        }
    }

    func clearLearnedTendencies() {
        // Suppress projection of any pre-reset stats; only new evidence will show
        capsule.learningResetAt = Date()
        capsule.learnedTendencies = []
        capsule.updatedAt = Date()
        persist()
    }

    /// Curated learned cues projection setter (idempotent caller should check, but we still persist once set).
    func setLearnedTendencies(_ items: [CapsuleTendency]) {
        capsule.learnedTendencies = items
        capsule.updatedAt = Date()
        persist()
    }

    // MARK: - Multi-select (typed)

    enum MultiSelectKey: String, CaseIterable {
        case dharmaPractices = "dharma:practices"
        case dharmaDeities = "dharma:deities"
        case dharmaTerms = "dharma:terms"
        case dharmaMilestones = "dharma:milestones"
    }

    func setMultiSelect(_ key: MultiSelectKey, values: [String]) {
        let cleaned = normaliseMultiSelect(values)

        var p = capsule.preferences
        switch key {
        case .dharmaPractices:  p.dharmaPractices = cleaned
        case .dharmaDeities:    p.dharmaDeities = cleaned
        case .dharmaTerms:      p.dharmaTerms = cleaned
        case .dharmaMilestones: p.dharmaMilestones = cleaned
        }

        // Keep the same data out of extras to avoid dual writes / truncation risks.
        p.extras.removeValue(forKey: key.rawValue)

        capsule.preferences = p
        capsule.updatedAt = Date()
        persist()
    }

    func multiSelect(_ key: MultiSelectKey) -> [String] {
        switch key {
        case .dharmaPractices:  return capsule.preferences.dharmaPractices
        case .dharmaDeities:    return capsule.preferences.dharmaDeities
        case .dharmaTerms:      return capsule.preferences.dharmaTerms
        case .dharmaMilestones: return capsule.preferences.dharmaMilestones
        }
    }

    // MARK: - Public API (compat key/value for your current UI)

    func setPreference(key: String, value: String) {
        let k = normaliseKey(key)
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !k.isEmpty else { return }

        // Back-compat: allow the UI to write multi-select as CSV; store it typed.
        if let msKey = MultiSelectKey(rawValue: k) {
            let decoded = decodeMultiSelectString(v)
            setMultiSelect(msKey, values: decoded)
            return
        }

        var p = capsule.preferences

        // Typed keys first
        switch k {
        case "output_style":
            p.outputStyle = v.isEmpty ? nil : String(v.prefix(extrasValueMax))

        case "options_before_questions":
            p.optionsBeforeQuestions = parseBool(v)

        case "no_therapy_framing":
            p.noTherapyFraming = parseBool(v)

        case "no_persona":
            p.noPersona = parseBool(v)

        default:
            // Open-ended extras (bounded)
            guard isAllowedExtraKey(k) else { return }

            let kk = String(k.prefix(extrasKeyMax))
            let vv = String(v.prefix(extrasValueMax))

            if vv.isEmpty {
                p.extras.removeValue(forKey: kk)
            } else {
                if p.extras[kk] == nil, p.extras.count >= extrasMaxItems {
                    // At cap, ignore new keys (simple, predictable)
                    return
                }
                p.extras[kk] = vv
            }
        }

        capsule.preferences = p
        capsule.updatedAt = Date()
        persist()
    }

    func removePreference(key: String) {
        let k = normaliseKey(key)
        guard !k.isEmpty else { return }

        if let msKey = MultiSelectKey(rawValue: k) {
            setMultiSelect(msKey, values: [])
            return
        }

        var p = capsule.preferences

        switch k {
        case "output_style":
            p.outputStyle = nil
        case "options_before_questions":
            p.optionsBeforeQuestions = nil
        case "no_therapy_framing":
            p.noTherapyFraming = nil
        case "no_persona":
            p.noPersona = nil
        default:
            p.extras.removeValue(forKey: String(k.prefix(extrasKeyMax)))
        }

        capsule.preferences = p
        capsule.updatedAt = Date()
        persist()
    }

    /// For your existing UI list rendering.
    var preferenceKeyValues: [(key: String, value: String)] {
        var out: [(key: String, value: String)] = []
        let p = capsule.preferences

        if let v = p.outputStyle, !v.isEmpty {
            out.append((key: "output_style", value: v))
        }
        if let b = p.optionsBeforeQuestions {
            out.append((key: "options_before_questions", value: b ? "true" : "false"))
        }
        if let b = p.noTherapyFraming {
            out.append((key: "no_therapy_framing", value: b ? "true" : "false"))
        }
        if let b = p.noPersona {
            out.append((key: "no_persona", value: b ? "true" : "false"))
        }

        // Multi-select (rendered as a readable list, but stored typed)
        if !p.dharmaPractices.isEmpty {
            out.append((key: MultiSelectKey.dharmaPractices.rawValue, value: p.dharmaPractices.joined(separator: ", ")))
        }
        if !p.dharmaDeities.isEmpty {
            out.append((key: MultiSelectKey.dharmaDeities.rawValue, value: p.dharmaDeities.joined(separator: ", ")))
        }
        if !p.dharmaTerms.isEmpty {
            out.append((key: MultiSelectKey.dharmaTerms.rawValue, value: p.dharmaTerms.joined(separator: ", ")))
        }
        if !p.dharmaMilestones.isEmpty {
            out.append((key: MultiSelectKey.dharmaMilestones.rawValue, value: p.dharmaMilestones.joined(separator: ", ")))
        }

        // Extras
        let extrasPairs = p.extras
            .map { (key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }

        out.append(contentsOf: extrasPairs)
        return out
    }

    // MARK: - Disk

    private func persist() {
        do {
            try saveToDisk(capsule)
        } catch {
            log.error("saveToDisk failed: \(String(describing: error), privacy: .private)")
        }
    }

    private func loadFromDisk() throws -> CapsuleModel {
        let url = try capsuleURL()
        guard fm.fileExists(atPath: url.path) else { return .empty() }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CapsuleModel.self, from: data)
    }

    private func saveToDisk(_ capsule: CapsuleModel) throws {
        let url = try capsuleURL()
        var c = capsule
        c.updatedAt = Date()
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

    // MARK: - Migration

    private func migrateCapsuleIfNeeded(_ capsule: CapsuleModel) -> (capsule: CapsuleModel, didChange: Bool) {
        var c = capsule
        var didChange = false

        // Move any legacy multi-select values out of extras into typed arrays.
        var p = c.preferences
        for key in MultiSelectKey.allCases {
            if let legacy = p.extras[key.rawValue], !legacy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let decoded = decodeMultiSelectString(legacy)
                let cleaned = normaliseMultiSelect(decoded)
                if !cleaned.isEmpty {
                    switch key {
                    case .dharmaPractices:  p.dharmaPractices = cleaned
                    case .dharmaDeities:    p.dharmaDeities = cleaned
                    case .dharmaTerms:      p.dharmaTerms = cleaned
                    case .dharmaMilestones: p.dharmaMilestones = cleaned
                    }
                }
                p.extras.removeValue(forKey: key.rawValue)
                didChange = true
            }
        }

        if didChange {
            c.preferences = p
            c.updatedAt = Date()
        }

        return (c, didChange)
    }

    // MARK: - Helpers

    private func normaliseKey(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return "" }

        let underscored = trimmed
            .replacingOccurrences(of: #"[\s\-]+"#, with: "_", options: .regularExpression)
            .replacingOccurrences(of: #"_{2,}"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return underscored
    }

    private func parseBool(_ s: String) -> Bool? {
        let v = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if v.isEmpty { return nil }
        if ["true", "1", "yes", "y", "on"].contains(v) { return true }
        if ["false", "0", "no", "n", "off"].contains(v) { return false }
        return nil
    }

    private func isAllowedExtraKey(_ k: String) -> Bool {
        k.range(of: #"^[a-z0-9]+(?:[:_][a-z0-9]+)*$"#, options: .regularExpression) != nil
    }

    private func decodeMultiSelectString(_ input: String) -> [String] {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return [] }

        // JSON array (preferred)
        if s.first == "[" {
            if let data = s.data(using: .utf8),
               let arr = try? JSONDecoder().decode([String].self, from: data) {
                return arr
            }
        }

        // CSV fallback (legacy)
        return s
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normaliseMultiSelect(_ values: [String]) -> [String] {
        var seen = Set<String>()
        let cleaned = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { v in
                let key = v.lowercased()
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }
        return cleaned.sorted()
    }
}
