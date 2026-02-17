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
        // Lower per-observation strength so one mention won’t surface immediately.
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
                out.append(.init(kind: .constraints_sensitivity, key: key, strength: 0.25))
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

        // MARK: explicit-phrase v1 for question/breadth density (low-authority)
        if let text = redactedText?.lowercased(), !text.isEmpty {
            out.append(contentsOf: deriveQuestionAndBreadthPreferences(from: text))
        }

        // MARK: NEW — Buddhist practice signals (explicit phrases only; no inference)
        if let text = redactedText?.lowercased(), !text.isEmpty {
            out.append(contentsOf: deriveBuddhistSignals(from: text))
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
            // Removed: "trigger:eye_contact"
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

    // explicit-phrase v1 for the four cues
    private func deriveQuestionAndBreadthPreferences(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        let qLight = [
            "stop asking questions", "just tell me", "don't ask me questions", "do not ask me questions",
            "no questions", "no more questions", "quit asking questions", "stop with the questions"
        ]
        if qLight.contains(where: { text.contains($0) }) {
            out.append(.init(kind: .workflow_preference, key: "question_light", strength: 0.5))
        }

        let qGuided = [
            "ask me questions", "help me think this through", "question me", "can you question me",
            "guide me with questions", "ask questions to help me think"
        ]
        if qGuided.contains(where: { text.contains($0) }) {
            out.append(.init(kind: .workflow_preference, key: "question_guided", strength: 0.5))
        }

        let narrow = [
            "one thing at a time", "just pick one", "too many options", "pick one for me",
            "choose one for me", "don't give me options", "do not give me options", "just choose for me", "pick one"
        ]
        if narrow.contains(where: { text.contains($0) }) {
            out.append(.init(kind: .workflow_preference, key: "narrow_first", strength: 0.5))
        }

        let explore = [
            "what are my options", "map it out", "what else could work", "alternatives",
            "explore options", "show me options", "option space", "lay out the options"
        ]
        if explore.contains(where: { text.contains($0) }) {
            out.append(.init(kind: .workflow_preference, key: "explore_space", strength: 0.5))
        }

        return out
    }

    // MARK: NEW — Buddhist practice signals (explicit phrases only)
    private func deriveBuddhistSignals(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        func hit(_ phrases: [String]) -> Bool { phrases.contains(where: { text.contains($0) }) }
        func add(_ key: String, _ strength: Double) {
            out.append(.init(kind: .topic_recurrence, key: key, strength: strength))
        }

        // --- Practice forms (explicit terms)
        let practices: [(String, [String])] = [
            ("shamatha", ["shamatha", "śamatha", "calm abiding", "calm-abiding", "tranquillity"]),
            ("vipashyana", ["vipashyana", "vipaśyanā", "vipassana", "insight meditation", "insight practice"]),
            ("lojong", ["lojong", "blo sbyong", "mind training"]),
            ("tonglen", ["tonglen", "gtong len"]),
            ("metta", ["metta", "mettā", "loving-kindness", "loving kindness"]),
            ("ngondro", ["ngondro", "ngöndro", "sngon 'gro", "preliminaries"]),
            ("deity_yoga", ["deity yoga", "generation stage", "kyerim", "bskyed rim"]),
            ("dzogchen", ["dzogchen", "rdzogs chen", "atiyoga", "trekchö", "trekcho", "thögal", "thogal"]),
            ("mahamudra", ["mahamudra", "mahāmudrā"]),
            ("koan", ["koan", "kōan"]),
            ("zazen", ["zazen", "shikantaza"])
        ]
        for (k, phrases) in practices where hit(phrases) {
            add("dharma:practice:\(k)", 0.35)
        }

        // --- Tradition/lineage lane (explicit mentions)
        let lineages: [(String, [String])] = [
            ("nyingma", ["nyingma"]),
            ("kagyu", ["kagyu", "kagyü"]),
            ("gelug", ["gelug", "geluk"]),
            ("sakya", ["sakya"]),
            ("zen", ["zen"]),
            ("theravada", ["theravada", "theravāda"]),
            ("secular", ["secular buddhism", "secular dharma"])
        ]
        for (k, phrases) in lineages where hit(phrases) {
            add("dharma:lineage:\(k)", 0.35)
        }

        // --- Stated level/experience (explicit phrases only)
        let levels: [(String, [String])] = [
            ("beginner", ["i'm a beginner", "im a beginner", "new to buddhism", "new to meditation", "just starting"]),
            ("returning", ["returning to practice", "back to practice", "starting again"]),
            ("experienced", ["i've practiced for", "i have practiced for", "years of practice", "long time practitioner"]),
            ("ordained", ["ordained", "monk", "nun", "lama", "ngakpa"]),
            ("ngondro_complete", ["completed ngondro", "completed ngöndro", "finished ngondro", "finished ngöndro"])
        ]
        for (k, phrases) in levels where hit(phrases) {
            add("dharma:level:\(k)", 0.35)
        }

        // --- Teacher / community (explicit; do NOT store names)
        // We only record that a teacher/community is referenced.
        if hit(["my teacher", "my lama", "my guru", "my roshi", "my ajahn", "my sangha", "our sangha"]) {
            add("dharma:teacher_mentioned", 0.30)
        }
        if hit(["rinpoche", "roshi", "ajahn", "sayadaw", "geshe", "khenpo", "lama", "guru"]) {
            add("dharma:title_terms_present", 0.25)
        }

        // --- Training / course / retreat / empowerment (explicit)
        let training: [(String, [String])] = [
            ("retreat_mentioned", ["retreat", "retreating", "in retreat", "silent retreat"]),
            ("course_mentioned", ["course", "programme", "program", "training course", "meditation course"]),
            ("empowerment_mentioned", ["empowerment", "wang", "dbang", "lung", "reading transmission", "tri", "instruction"]),
            ("ordination_mentioned", ["ordained", "ordination", "monastic", "took vows", "vows"])
        ]
        for (k, phrases) in training where hit(phrases) {
            add("dharma:training:\(k)", 0.30)
        }

        // --- Language / comprehension (explicit only)
        // Keep coarse; avoid inferring proficiency.
        let languageClaims: [(String, [String])] = [
            ("english_only", ["only english", "just english", "i only speak english", "i only speak english"]),
            ("non_native_english", ["english isn't my first language", "english is not my first language", "non-native english"]),
            ("tibetan_some", ["a bit of tibetan", "some tibetan", "basic tibetan", "i can read tibetan"]),
            ("sanskrit_some", ["a bit of sanskrit", "some sanskrit", "basic sanskrit"])
        ]
        for (k, phrases) in languageClaims where hit(phrases) {
            add("profile:language:\(k)", 0.25)
        }

        // --- Country / region (explicit only; keep coarse)
        // Only catch a small allowlist; expand later if needed.
        let countryClaims: [(String, [String])] = [
            ("uk", ["i'm in the uk", "i am in the uk", "i live in the uk", "i'm in england", "i am in england"]),
            ("us", ["i'm in the us", "i am in the us", "i live in the us", "i'm in america", "i am in america"]),
            ("eu", ["i'm in europe", "i am in europe", "i live in europe"]),
            ("india", ["i'm in india", "i am in india", "i live in india"]),
            ("japan", ["i'm in japan", "i am in japan", "i live in japan"])
        ]
        for (k, phrases) in countryClaims where hit(phrases) {
            add("profile:country:\(k)", 0.25)
        }

        // --- Motivation / aim (explicit)
        if hit(["liberation", "awakening", "enlightenment", "buddhahood"]) {
            add("dharma:aim:liberation", 0.25)
        }
        if hit(["compassion", "bodhicitta", "benefit others", "help others"]) {
            add("dharma:aim:bodhicitta", 0.25)
        }

        // --- Strength / struggle (explicit “I’m good at…” / “I struggle with…” patterns)
        // These are signals, not truths. Keep them coarse.
        let struggleMarkers = ["i struggle with", "i find it hard to", "i can't", "i cannot", "i have trouble", "i find it difficult to"]
        if struggleMarkers.contains(where: { text.contains($0) }) {
            add("self:claim:struggle_mentioned", 0.20)
            if hit(["focus", "concentration", "distracted", "distraction"]) { add("self:struggle:focus", 0.25) }
            if hit(["anxiety", "worry", "panic"]) { add("self:struggle:anxiety", 0.25) }
            if hit(["anger", "irritation", "resentment"]) { add("self:struggle:anger", 0.25) }
            if hit(["compassion", "kindness"]) { add("self:struggle:compassion", 0.20) }
            if hit(["sleep", "tired", "exhausted"]) { add("self:struggle:sleep_energy", 0.25) }
        }

        let strengthMarkers = ["i'm good at", "i am good at", "i'm very good at", "i am very good at", "my strength is", "i'm strong at", "i am strong at"]
        if strengthMarkers.contains(where: { text.contains($0) }) {
            add("self:claim:strength_mentioned", 0.20)
            if hit(["focus", "concentration", "steady attention"]) { add("self:strength:focus", 0.25) }
            if hit(["discipline", "consistent", "routine"]) { add("self:strength:discipline", 0.25) }
            if hit(["study", "reading", "learning"]) { add("self:strength:study", 0.20) }
            if hit(["compassion", "kindness", "patience"]) { add("self:strength:heart", 0.20) }
        }

        // Avoid flooding
        return Array(out.prefix(8))
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
        let kindRaw = kind.rawValue
        let keyValue = key

        let descriptor = FetchDescriptor<PatternStatsEntity>(
            predicate: #Predicate { $0.kindRaw == kindRaw && $0.key == keyValue },
            sortBy: []
        )
        let matches = try context.fetch(descriptor)

        if let row = matches.first {
            let hl = max(1.0, row.halfLifeDays)
            let deltaDays = max(0, now.timeIntervalSince(row.lastSeenAt) / (60 * 60 * 24))
            let decayFactor = pow(0.5, deltaDays / hl)

            let decayed = row.score * decayFactor
            row.score = min(1.0, decayed + max(0.0, increment))
            row.count &+= 1
            row.lastSeenAt = now
        } else {
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

