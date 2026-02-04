import Foundation
import SwiftData

struct PatternObservation: Sendable, Equatable {
    let kind: PatternStatsEntity.Kind
    let key: String
    let strength: Double   // 0...1 (small increments per observation)
}

struct PatternLearner {

    // MARK: - Public API

    // Back-compat: keep the original signature
    func deriveObservations(from validated: ValidatedWalSnapshot) -> [PatternObservation] {
        deriveObservations(from: validated, redactedText: nil)
    }

    // Preferred: include local redacted text for explicit-phrase learners (situational constraints, release)
    func deriveObservations(from validated: ValidatedWalSnapshot, redactedText: String?) -> [PatternObservation] {
        var out: [PatternObservation] = []

        let snapshot = validated.snapshot
        let lift0 = snapshot.wal.lift0_context
        let desired = Set(lift0.desired_output.map { $0.lowercased() })
        let constraints = Set(lift0.constraints.map { $0.lowercased() })

        // Lift1 primitives (strings already canonicalised by WALValidator)
        let dom = Set(snapshot.wal.lift1_primitives.dominant.map { $0.lowercased() })
        let bg = Set(snapshot.wal.lift1_primitives.background.map { $0.lowercased() })

        // Meta: one_confirmation_question is non-empty when confirmation is suggested
        let needsConfirmation = !snapshot.wal.meta.one_confirmation_question
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        // MARK: Style preferences (format + density)
        if desired.contains("steps") || desired.contains("checklist") {
            out.append(.init(kind: .style_preference, key: "bullets", strength: 0.7))
        }
        if desired.contains("summary") {
            out.append(.init(kind: .style_preference, key: "concise", strength: 0.5))
        }
        if desired.contains("script") {
            out.append(.init(kind: .style_preference, key: "scripted_reply", strength: 0.5))
        }

        // Brevity/depth + layering
        if desired.contains("summary") && (desired.contains("steps") || desired.contains("checklist")) {
            out.append(.init(kind: .style_preference, key: "prefers_tldr_then_detail", strength: 0.6))
        } else if desired.contains("summary") {
            out.append(.init(kind: .style_preference, key: "prefers_brief", strength: 0.5))
        }

        if desired.contains("steps") {
            out.append(.init(kind: .style_preference, key: "prefers_numbered_steps", strength: 0.6))
        }
        if desired.contains("checklist") {
            out.append(.init(kind: .style_preference, key: "prefers_checklist", strength: 0.6))
        }
        if desired.contains("decision_tree") {
            out.append(.init(kind: .style_preference, key: "prefers_decision_tree", strength: 0.6))
        }

        // High urgency/stakes or time constraint -> no-fluff bias
        if lift0.urgency == .high || lift0.stake_level == .high || constraints.contains("time") {
            out.append(.init(kind: .style_preference, key: "prefers_no_fluff", strength: 0.4))
        }

        // MARK: Workflow preferences (conversation control)
        if desired.contains("options") {
            out.append(.init(kind: .workflow_preference, key: "options_first", strength: 0.6))
        }

        if needsConfirmation {
            out.append(.init(kind: .workflow_preference, key: "prefers_confirm_then_execute", strength: 0.4))
        } else {
            // If user leans toward direct outputs and not questions, prefer fewer/no questions
            let wantsDirect = desired.contains("steps") || desired.contains("options") || desired.contains("summary")
            let wantsQuestions = desired.contains("questions")
            if wantsDirect && !wantsQuestions {
                out.append(.init(kind: .workflow_preference, key: "prefers_execute_immediately", strength: 0.3))
                out.append(.init(kind: .workflow_preference, key: "prefers_few_questions", strength: 0.3))
                if desired.contains("summary") {
                    out.append(.init(kind: .workflow_preference, key: "prefers_just_answer", strength: 0.3))
                }
            }
        }

        // MARK: Resolution patterns (how to proceed effectively; not identity)
        if !lift0.constraints.isEmpty {
            out.append(.init(kind: .resolution_pattern, key: "constraints_first", strength: 0.5))
        }
        if lift0.intent_primary == .decide && (dom.contains("intolerance_of_uncertainty") || bg.contains("intolerance_of_uncertainty")) {
            out.append(.init(kind: .resolution_pattern, key: "decision_stuck", strength: 0.6))
        }
        if lift0.intent_primary == .vent && constraints.contains("energy") {
            out.append(.init(kind: .resolution_pattern, key: "needs_decompression", strength: 0.6))
        }
        if constraints.count >= 3 {
            out.append(.init(kind: .resolution_pattern, key: "complexity_high", strength: 0.5))
        }
        if desired.contains("reframe") && (desired.contains("steps") || desired.contains("checklist")) {
            out.append(.init(kind: .resolution_pattern, key: "prefers_reframe_then_steps", strength: 0.5))
        }

        // MARK: Constraints sensitivities (non-clinical; user-stated only via Lift0)
        let constraintMap: [String: String] = [
            "time": "time_pressure",
            "energy": "low_energy",
            "money": "money_limit",
            "social": "social_overload",
            "dependencies": "dependency_blocked",
            "sensory": "sensory_noise",
            "legal": "legal_risk"
        ]
        for c in constraints {
            if let key = constraintMap[c] {
                out.append(.init(kind: .constraints_sensitivity, key: key, strength: 0.5))
            }
        }

        // MARK: Narrative patterns (derived from primitives; bounded, non-identity)
        func addNarrative(_ primitive: String, key: String) {
            if dom.contains(primitive) {
                out.append(.init(kind: .narrative_pattern, key: key, strength: 0.6))
            } else if bg.contains(primitive) {
                out.append(.init(kind: .narrative_pattern, key: key, strength: 0.4))
            }
        }
        addNarrative("narrative_looping", key: "replay_loop")
        addNarrative("identity_tightening", key: "identity_frame_present")
        addNarrative("attachment_to_outcome", key: "outcome_fixation")
        addNarrative("control_seeking", key: "control_frame")
        addNarrative("intolerance_of_uncertainty", key: "uncertainty_pressure")
        addNarrative("self_judgement", key: "self_attack_language")
        addNarrative("reassurance_seeking", key: "reassurance_checking")
        addNarrative("aversion_resistance", key: "avoidance_language")

        // MARK: Contraction patterns (conditions that tighten; from primitives only)
        func addContraction(_ primitive: String, key: String) {
            if dom.contains(primitive) {
                out.append(.init(kind: .contraction_pattern, key: "contraction:\(key)", strength: 0.6))
            } else if bg.contains(primitive) {
                out.append(.init(kind: .contraction_pattern, key: "contraction:\(key)", strength: 0.4))
            }
        }
        addContraction("identity_tightening", key: "identity_fixation")
        addContraction("attachment_to_outcome", key: "outcome_fixation")
        addContraction("control_seeking", key: "control_pressure")
        addContraction("intolerance_of_uncertainty", key: "uncertainty_pressure")
        addContraction("narrative_looping", key: "mental_looping")
        addContraction("self_judgement", key: "self_attack")
        addContraction("reassurance_seeking", key: "checking_for_reassurance")
        addContraction("aversion_resistance", key: "avoidance_pressure")

        // MARK: Release patterns (conditions that coincide with ease; explicit phrases only)
        if let text = redactedText?.lowercased(), !text.isEmpty {
            out.append(contentsOf: deriveReleaseObservations(from: text))
        }

        // MARK: Situational constraints (explicit phrases only; local redacted text)
        if let text = redactedText?.lowercased(), !text.isEmpty {
            out.append(contentsOf: deriveSituationalConstraints(from: text))
        }

        // Keep bounded and deduplicated per (kind,key)
        var unique: [String: PatternObservation] = [:]
        for o in out {
            unique["\(o.kind.rawValue)|\(o.key)"] = o
        }
        // Bound per-turn emission to a small set
        return Array(unique.values).prefix(12).map { $0 }
    }

    // Explicit-phrase allowlist only; no inference.
    private func deriveSituationalConstraints(from text: String) -> [PatternObservation] {
        let mapping: [String: [String]] = [
            // Sensory
            "trigger:noise": ["noise", "noisy", "too loud", "loud noise", "loud noises", "background noise"],
            "trigger:bright_light": ["bright light", "bright lights", "glare", "fluorescent light", "fluorescent lights"],
            "trigger:crowds": ["crowds", "crowded", "crowded places", "busy places", "too many people"],

            // Social
            "trigger:eye_contact": ["eye contact"],
            "trigger:group_dynamics": ["group dynamics"],
            "trigger:hierarchy_games": ["hierarchy games", "power games", "status games", "power dynamics"],
            "trigger:being_observed": ["being watched", "being observed", "people watching me"],

            // Cognitive load
            "trigger:too_many_variables": ["too many variables", "too many moving parts", "too many factors"],
            "trigger:unclear_requirements": ["unclear requirements", "requirements unclear", "not clear what is needed"],
            "trigger:interruptions": ["interruptions", "interrupted", "getting interrupted"],
            "trigger:context_switching": ["context switching", "switching context", "switching tasks", "task switching"],

            // Time / energy
            "trigger:deadline_pressure": ["deadline pressure", "tight deadline", "deadline looming"],
            "trigger:low_sleep": ["low sleep", "no sleep", "little sleep", "sleep deprived", "didn't sleep", "did not sleep"],
            "trigger:low_energy": ["low energy", "exhausted", "tired", "burnt out", "burned out"]
        ]

        var out: [PatternObservation] = []
        for (key, phrases) in mapping {
            if phrases.contains(where: { text.contains($0) }) {
                out.append(.init(kind: .constraint_trigger, key: key, strength: 0.4))
            }
        }
        // Avoid flooding: keep a small number of situational items per turn
        return Array(out.prefix(6))
    }

    // Explicit relief phrases only; no inference from silence/fewer reruns.
    private func deriveReleaseObservations(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        let easePhrases = [
            "ease", "easier", "with ease", "can breathe", "could breathe",
            "breathing easier", "relief", "relieved"
        ]
        let settlingPhrases = [
            "settled", "settling", "less tight", "less tense", "unclench",
            "soften", "softening"
        ]
        let opennessPhrases = [
            "more space", "there is space", "space opened", "spacious",
            "feel space", "sense of space", "let go", "dropped it", "drop it"
        ]

        if easePhrases.contains(where: { text.contains($0) }) {
            out.append(.init(kind: .release_pattern, key: "release:ease_present", strength: 0.4))
        }
        if settlingPhrases.contains(where: { text.contains($0) }) {
            out.append(.init(kind: .release_pattern, key: "release:settling", strength: 0.4))
        }
        if opennessPhrases.contains(where: { text.contains($0) }) {
            out.append(.init(kind: .release_pattern, key: "release:openness", strength: 0.3))
        }

        return out
    }

    @MainActor
    func apply(observations: [PatternObservation], into context: ModelContext, now: Date = Date()) throws {
        guard !observations.isEmpty else { return }

        for obs in observations {
            try upsert(kind: obs.kind, key: obs.key, increment: obs.strength, now: now, context: context)
        }

        try context.save()
    }

    // MARK: - Internals

    @MainActor
    private func upsert(kind: PatternStatsEntity.Kind, key: String, increment: Double, now: Date, context: ModelContext) throws {
        // Bind raw values to concrete constants to avoid key-path RHS in predicate builder
        let kindRaw = kind.rawValue
        let keyValue = key

        // Fetch existing row (unique by kind+key)
        let descriptor = FetchDescriptor<PatternStatsEntity>(
            predicate: #Predicate { $0.kindRaw == kindRaw && $0.key == keyValue },
            sortBy: [] // single row expected
        )
        let matches = try context.fetch(descriptor)

        if let row = matches.first {
            // Exponential decay: score *= decayFactor; then add increment
            let hl = max(1.0, row.halfLifeDays)
            let deltaDays = max(0, now.timeIntervalSince(row.lastSeenAt) / (60 * 60 * 24))
            let decayFactor = pow(0.5, deltaDays / hl)

            let decayed = row.score * decayFactor
            row.score = min(1.0, decayed + max(0.0, increment))
            row.count &+= 1
            row.lastSeenAt = now
        } else {
            // New row
            let row = PatternStatsEntity(
                kindRaw: kindRaw,
                key: keyValue,
                score: min(1.0, max(0.0, increment)),
                count: 1,
                firstSeenAt: now,
                lastSeenAt: now,
                halfLifeDays: 14.0
            )
            context.insert(row)
        }
    }
}
