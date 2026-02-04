import Foundation

struct WALSnapshotV1: Codable, Equatable, Sendable {
    struct Lift1Primitives: Codable, Equatable, Sendable {
        var dominant: [String]
        var background: [String]
    }
    struct Lift2Lenses: Codable, Equatable, Sendable {
        var primary: String?
        var secondary: String?
    }
    struct Meta: Codable, Equatable, Sendable {
        var field_meta: [String: FieldMeta]
        var consistency_checks: [Consistency]
        var one_confirmation_question: String
    }
    struct FieldMeta: Codable, Equatable, Sendable {
        var source: String         // rule|user_stated|direct_text|cloud_proposal
        var confidence: String     // low|med|high
        var needs_confirmation: Bool
        var time_scope: String     // session_only|rolling_window
        var evidence: [String]
        var rationale: String?
    }
    struct Consistency: Codable, Equatable, Sendable {
        var issue: String
        var fields: [String]
        var severity: String       // low|med|high
        var proposed_fix: String
    }

    struct WALBody: Codable, Equatable, Sendable {
        var lift0_context: Lift0Context
        var lift1_primitives: Lift1Primitives
        var lift2_lenses: Lift2Lenses
        var meta: Meta
    }

    var wal: WALBody
    var pattern_signals: [String]
    var capsule_suggestions: [String]
    var provenance: [String: String] // built_by: local|hybrid, cloudtap_used: true|false
    var updatedAtISO: String
    var version: Int
}

// Type barrier: only validated snapshots can be fed to learning.
struct ValidatedWalSnapshot: Sendable, Equatable {
    let snapshot: WALSnapshotV1
    var isValidated: Bool { true }

    // Only WALValidator (and any reconciler living in this file) can construct it.
    fileprivate init(snapshot: WALSnapshotV1) {
        self.snapshot = snapshot
    }
}

struct WALValidator {
    private let maxSummaryChars = 280
    private let maxEvidencePerField = 6

    func validate(
        lift0: Lift0Context,
        primitiveDominant: [CanonicalPrimitive],
        primitiveBackground: [CanonicalPrimitive],
        candidates: [PrimitiveCandidate],
        lenses: LensSelection,
        confirmationNeeded: Bool
    ) -> ValidatedWalSnapshot {
        // Clamp counts per spec
        let dom = Array(primitiveDominant.prefix(2)).map { $0.rawValue }
        let bg = Array(primitiveBackground.prefix(1)).map { $0.rawValue }

        let primary = lenses.primary?.rawValue
        let secondary = lenses.secondary?.rawValue

        // Build minimal field_meta from candidates evidence/confidence
        var fm: [String: WALSnapshotV1.FieldMeta] = [:]
        for c in candidates.prefix(8) {
            let key = "wal.lift1_primitives.\(c.primitive.rawValue)"
            fm[key] = WALSnapshotV1.FieldMeta(
                source: "rule",
                confidence: c.confidence,
                needs_confirmation: confirmationNeeded && (c.score < 70),
                time_scope: "session_only",
                evidence: Array(c.evidence.prefix(maxEvidencePerField)),
                rationale: nil
            )
        }

        let body = WALSnapshotV1.WALBody(
            lift0_context: clampLift0(lift0),
            lift1_primitives: .init(dominant: dom, background: bg),
            lift2_lenses: .init(primary: primary, secondary: secondary),
            meta: .init(field_meta: fm, consistency_checks: [], one_confirmation_question: confirmationNeeded ? makeOneQuestion(dom: dom, bg: bg) : "")
        )

        let out = WALSnapshotV1(
            wal: body,
            pattern_signals: [],
            capsule_suggestions: [],
            provenance: ["built_by": "local", "cloudtap_used": "false"],
            updatedAtISO: ISO8601DateFormatter().string(from: Date()),
            version: 1
        )
        return ValidatedWalSnapshot(snapshot: out)
    }

    private func clampLift0(_ c: Lift0Context) -> Lift0Context {
        var out = c
        out.desired_output = Array(Set(out.desired_output)).prefix(4).map { $0 }
        out.constraints = Array(Set(out.constraints)).prefix(6).map { $0 }
        return out
    }

    private func makeOneQuestion(dom: [String], bg: [String]) -> String {
        // Simple question generator – keep ≤160 chars
        if let d = dom.first {
            return "Does \(d.replacingOccurrences(of: "_", with: " ")) fit today, or is it something else?"
        }
        if let b = bg.first {
            return "Is \(b.replacingOccurrences(of: "_", with: " ")) showing up here?"
        }
        return ""
    }
}
