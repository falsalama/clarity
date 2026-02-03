import Foundation
import Combine

@MainActor
final class CapsuleStore: ObservableObject {
    @Published private(set) var capsule: CapsuleModel = .empty()

    private let fm = FileManager.default

    // Bounds for open-ended extras
    private let extrasMaxItems = 24
    private let extrasKeyMax = 32
    private let extrasValueMax = 128

    init() {
        do {
            self.capsule = try loadFromDisk()
        } catch {
            self.capsule = .empty()
        }
    }
    
    @MainActor
    func setPseudonym(_ value: String) {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        capsule.preferences.pseudonym = v.isEmpty ? nil : v
        capsule.updatedAt = Date()
        persist()
    }


    // MARK: - Public API (typed)

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
        do { try wipeFromDisk() } catch { }
    }

    // MARK: - Public API (compat key/value for your current UI)

    func setPreference(key: String, value: String) {
        let k = normaliseKey(key)
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !k.isEmpty else { return }

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

        // Extras
        let extrasPairs = p.extras
            .map { (key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }

        out.append(contentsOf: extrasPairs)

        return out
    }

    // MARK: - Disk

    private func persist() {
        do { try saveToDisk(capsule) } catch { }
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
        // after normaliseKey, only allow [a-z0-9_]
        k.range(of: #"^[a-z0-9_]+$"#, options: .regularExpression) != nil
    }
}

