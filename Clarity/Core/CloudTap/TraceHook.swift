import Foundation
import OSLog

// TRACE-DEBUG / PRISM-DEBUG
// Purpose: single place to inspect CloudTap export/import during dev.
// Delete this file + the two call sites in CloudTapService when done.

#if DEBUG
enum CloudTapTraceHook {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Clarity",
        category: "CloudTapTrace"
    )

    static func emit(endpoint: String, requestBody: Data?) {
        let fp = fingerprint(requestBody)
        let summary = exportSummary(from: requestBody)
        logger.debug("PRISM Export endpoint=\(endpoint, privacy: .public) fp=\(fp, privacy: .public) \(summary, privacy: .public)")
    }

    static func emitResponse(endpoint: String, responseBody: Data) {
        let fp = fingerprint(responseBody)
        let snippet = responseSnippet(responseBody)
        logger.debug("PRISM Response endpoint=\(endpoint, privacy: .public) fp=\(fp, privacy: .public) snippet=\(snippet, privacy: .private)")
    }

    // MARK: - Helpers

    private static func fingerprint(_ data: Data?) -> String {
        guard let data else { return "nil" }
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for b in data {
            hash ^= UInt64(b)
            hash &*= prime
        }
        return String(format: "%016llx", hash)
    }

    private static func exportSummary(from httpBody: Data?) -> String {
        guard
            let httpBody,
            let obj = try? JSONSerialization.jsonObject(with: httpBody, options: []),
            let dict = obj as? [String: Any]
        else {
            return "no-body"
        }

        guard let capsule = dict["capsule"] as? [String: Any] else {
            return "no-capsule"
        }

        let prefKeys = (capsule["preferences"] as? [String: Any])?.keys.sorted() ?? []
        let cuesCount = (capsule["learnedCues"] as? [[String: Any]])?.count ?? 0

        let prefCount = prefKeys.count
        let prefPreview = prefKeys.prefix(10).joined(separator: ",")
        return "prefs=\(prefCount) cues=\(cuesCount) keys=\(prefPreview)"
    }

    private static func responseSnippet(_ data: Data) -> String {
        let s = String(data: data, encoding: .utf8) ?? ""
        if s.count <= 400 { return s }
        let idx = s.index(s.startIndex, offsetBy: 400)
        return String(s[..<idx]) + "…"
    }
}
#else
// In non-DEBUG builds, compile away.
enum CloudTapTraceHook {
    static func emit(endpoint: String, requestBody: Data?) {}
    static func emitResponse(endpoint: String, responseBody: Data) {}
}
#endif
