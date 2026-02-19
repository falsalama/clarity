import Foundation
import SwiftData

struct PatternObservation: Sendable, Equatable {
    let kind: PatternStatsEntity.Kind
    let key: String
    let strength: Double   // typically -1...1 (positive reinforces, negative deactivates)
}

struct PatternLearner {

    /// Normalise user text for phrase-matching.
    ///
    /// Goal: widen the net without adding inference.
    /// - lowercases
    /// - removes diacritics
    /// - converts punctuation/symbols to spaces
    /// - collapses whitespace
    ///
    /// Example: "I’m 50 - from England" -> "im 50 from england"
    nonisolated private static func normalise(_ s: String) -> String {
        // Lowercase + strip diacritics.
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        // Convert punctuation/symbols into spaces so phrase boundaries survive.
        let chars: [Character] = folded.unicodeScalars.map { scalar in
            if CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) {
                return Character(scalar)
            }

            // Drop apostrophes so “I’m” -> “im”.
            if scalar == "'" || scalar == "’" {
                return "\0"
            }

            // Everything else becomes a space.
            return " "
        }

        let raw = String(chars).replacingOccurrences(of: "\0", with: "")

        // Collapse whitespace.
        let parts = raw.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

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

        let text = redactedText.map(Self.normalise)
        if let text, !text.isEmpty {
            // MARK: Release patterns (conditions that coincide with ease; explicit phrases only)
            out.append(contentsOf: deriveReleaseObservations(from: text))

            // MARK: Situational constraints (explicit phrases only; local redacted text)
            out.append(contentsOf: deriveSituationalConstraints(from: text))

            // MARK: explicit-phrase v1 for question/breadth density (low-authority)
            out.append(contentsOf: deriveQuestionAndBreadthPreferences(from: text))

            // MARK: Profile signals (explicit phrases only; local redacted text)
            out.append(contentsOf: deriveProfileSignals(from: text))

            // MARK: Buddhist practice signals (explicit phrases only; no inference)
            out.append(contentsOf: deriveBuddhistSignals(from: text))

            // MARK: Dharma milestones (explicit phrases only; no inference)
            out.append(contentsOf: deriveDharmaMilestones(from: text))

            // MARK: Explicit deactivation phrases (agency-first; no inference)
            out.append(contentsOf: deriveDeactivations(from: text))
        }

        // Keep bounded and deduplicated per (kind,key) with deterministic ordering.
        // Dedupe keeps the max strength for a given (kind,key).
        var unique: [String: PatternObservation] = [:]
        for o in out {
            let k = "\(o.kind.rawValue)|\(o.key)"
            if let existing = unique[k] {
                if o.strength > existing.strength { unique[k] = o }
            } else {
                unique[k] = o
            }
        }

        let sorted = unique.values.sorted { a, b in
            if a.strength != b.strength { return a.strength > b.strength }
            return a.key < b.key
        }

        // Bound per-turn emission to a small, stable set.
        // Reserve slots so profile/dharma tags don't get squeezed out by high-strength style/narrative items.
        return selectBounded(sorted, maxTotal: 20)
    }

    private func selectBounded(_ sorted: [PatternObservation], maxTotal: Int) -> [PatternObservation] {
        if sorted.isEmpty { return [] }

        func priorityScore(for o: PatternObservation) -> Int {
            // Higher is better.
            if o.kind != .topic_recurrence { return 0 }

            // Profile priorities
            if o.key.hasPrefix("profile:language:") { return 900 }
            if o.key.hasPrefix("profile:country:") { return 800 }
            if o.key.hasPrefix("profile:region:") { return 700 }
            if o.key.hasPrefix("profile:residence_long_term:") { return 650 }
            if o.key.hasPrefix("profile:residence:") { return 600 }
            if o.key.hasPrefix("profile:age_band:") { return 500 }
            if o.key.hasPrefix("profile:age_decade:") { return 450 }

            // Dharma priorities
            if o.key.hasPrefix("dharma:practice:ngondro_complete") { return 950 }
            if o.key.hasPrefix("dharma:milestone:") { return 940 }
            if o.key.hasPrefix("dharma:practice:") { return 900 }
            if o.key.hasPrefix("dharma:role:") { return 850 }
            if o.key.hasPrefix("dharma:school:") { return 820 }
            if o.key.hasPrefix("dharma:lineage:") { return 810 }
            if o.key.hasPrefix("dharma:vehicle:") { return 800 }
            if o.key.hasPrefix("dharma:experience:") { return 780 }
            if o.key.hasPrefix("dharma:deity:") { return 700 }
            if o.key.hasPrefix("dharma:term:") { return 650 }

            return 100
        }

        // Split buckets
        var profile = sorted.filter { $0.kind == .topic_recurrence && $0.key.hasPrefix("profile:") }
        var dharma  = sorted.filter { $0.kind == .topic_recurrence && $0.key.hasPrefix("dharma:") }
        let other   = sorted.filter {
            !($0.kind == .topic_recurrence && ($0.key.hasPrefix("profile:") || $0.key.hasPrefix("dharma:")))
        }

        // Priority ordering inside profile/dharma (then strength, then recency-ish stable key)
        profile.sort {
            let pa = priorityScore(for: $0), pb = priorityScore(for: $1)
            if pa != pb { return pa > pb }
            if $0.strength != $1.strength { return $0.strength > $1.strength }
            return $0.key < $1.key
        }
        dharma.sort {
            let pa = priorityScore(for: $0), pb = priorityScore(for: $1)
            if pa != pb { return pa > pb }
            if $0.strength != $1.strength { return $0.strength > $1.strength }
            return $0.key < $1.key
        }

        // Target mix (still capped at maxTotal)
        let targetOther = max(0, min(maxTotal, 8))
        let targetProfile = max(0, min(maxTotal - targetOther, 2))
        let targetDharma = max(0, min(maxTotal - targetOther - targetProfile, 4))

        var picked: [PatternObservation] = []
        picked.reserveCapacity(maxTotal)

        func appendUnique<S: Sequence>(_ items: S) where S.Element == PatternObservation {
            for o in items {
                if picked.count >= maxTotal { return }
                if !picked.contains(where: { $0.kind == o.kind && $0.key == o.key }) {
                    picked.append(o)
                }
            }
        }

        appendUnique(other.prefix(targetOther))
        appendUnique(profile.prefix(targetProfile))
        appendUnique(dharma.prefix(targetDharma))

        if picked.count < maxTotal { appendUnique(other.dropFirst(targetOther).prefix(maxTotal - picked.count)) }
        if picked.count < maxTotal { appendUnique(profile.dropFirst(targetProfile).prefix(maxTotal - picked.count)) }
        if picked.count < maxTotal { appendUnique(dharma.dropFirst(targetDharma).prefix(maxTotal - picked.count)) }

        return picked
    }

    // MARK: - Persistence policy

    /// Persistence policy for learned items.
    /// - sticky: comfort/safety triggers + hard preferences (do not "forget" just because they weren't mentioned)
    /// - seasonal: preferences that can evolve
    /// - ephemeral: day-state
    private func halfLifeDays(for kind: PatternStatsEntity.Kind, key: String) -> Double {
        // Ephemeral (days)
        if key.hasPrefix("release:") { return 7 }
        if key.contains("deadline") || key.contains("time_pressure") { return 7 }
        if key.contains("low_energy") || key.contains("low_sleep") { return 7 }

        // Sticky (months)
        if kind == .constraint_trigger { return 365 }
        if key.hasPrefix("trigger:") { return 365 }
        if key == "question_light" { return 180 }
        if key == "prefers_no_fluff" { return 120 }

        // Seasonal (weeks–months)
        if kind == .style_preference || kind == .workflow_preference { return 90 }

        // Default
        return 14
    }

    // Explicit deactivation allowlist only; never inferred.
    // Emit negative observations so sticky items can be explicitly released.
    private func deriveDeactivations(from text: String) -> [PatternObservation] {
        let deactivationMarkers = [
            "not anymore",
            "no longer",
            "its fine now",
            "it is fine now",
            "stop doing that",
            "dont do that",
            "do not do that",
            "you can stop",
            "i dont need that",
            "i do not need that"
        ]
        guard deactivationMarkers.contains(where: { text.contains($0) }) else { return [] }

        // Minimal v1: allow deactivating the most common sticky triggers by explicit mention.
        // (Only if the key itself appears in the text.)
        let knownStickyKeys: [(PatternStatsEntity.Kind, String, [String])] = [
            (.constraint_trigger, "trigger:noise", ["noise", "noisy", "too loud", "loud noise", "loud noises", "background noise"]),
            (.constraint_trigger, "trigger:bright_light", ["bright light", "bright lights", "glare", "fluorescent light", "fluorescent lights"]),
            (.constraint_trigger, "trigger:crowds", ["crowds", "crowded", "crowded places", "busy places", "too many people"]),
            (.constraint_trigger, "trigger:hierarchy_games", ["hierarchy games", "power games", "status games", "power dynamics"]),
            (.constraint_trigger, "trigger:being_observed", ["being watched", "being observed", "people watching me"]),
            (.constraints_sensitivity, "sensory_noise", ["noise", "noisy", "too loud", "loud noise", "loud noises", "background noise"]),
            (.workflow_preference, "question_light", ["stop asking questions", "no questions", "stop with the questions"])
        ]

        var out: [PatternObservation] = []
        for (kind, key, phrases) in knownStickyKeys {
            if phrases.contains(where: { text.contains($0) }) {
                out.append(.init(kind: kind, key: key, strength: -0.6))
            }
        }
        return out
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
            "trigger:low_sleep": ["low sleep", "no sleep", "little sleep", "sleep deprived", "didnt sleep", "did not sleep"],
            "trigger:low_energy": ["low energy", "exhausted", "tired", "burnt out", "burned out"]
        ]

        var out: [PatternObservation] = []
        for (key, phrases) in mapping {
            if phrases.contains(where: { text.contains($0) }) {
                out.append(.init(kind: .constraint_trigger, key: key, strength: 0.4))
            }
        }
        // Avoid flooding: keep a small number of situational items per turn
        return Array(out.prefix(8))
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
            "stop asking questions", "just tell me", "dont ask me questions", "do not ask me questions",
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
            "choose one for me", "dont give me options", "do not give me options", "just choose for me", "pick one"
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

    // MARK: - Regex helpers (explicit only)

    private func containsRegex(_ pattern: String, in text: String) -> Bool {
        guard let r = try? NSRegularExpression(pattern: pattern) else { return false }
        return r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private func escapeRegex(_ s: String) -> String {
        NSRegularExpression.escapedPattern(for: s)
    }

    // MARK: NEW — Profile signals (explicit phrases only)
    private func deriveProfileSignals(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        // IMPORTANT: topic_recurrence items must clear LearningSync thresholds (>= ~0.30),
        // otherwise they never persist. Keep these >= 0.32 by default.
        func add(_ key: String, _ strength: Double = 0.34) {
            out.append(.init(kind: .topic_recurrence, key: key, strength: strength))
        }

        func hitAny(_ phrases: [String]) -> Bool {
            phrases.contains(where: { text.contains($0) })
        }

        // --- Language (explicit patterns)
        if hitAny([
            "english only", "only english", "i only speak english", "i just speak english",
            "i speak english", "english is my first language"
        ]) {
            add("profile:language:english", 0.32)
        }
        if hitAny([
            "english isnt my first language", "english is not my first language", "non native english", "non-native english"
        ]) {
            add("profile:language:non_native_english", 0.32)
        }

        // --- Country / region (explicit phrasing)
        // Store coarse key only.
        let countries: [(String, [String])] = [
            ("uk", ["united kingdom", "u.k.", "uk", "the uk", "britain", "great britain", "england", "scotland", "wales", "northern ireland"]),
            ("ireland", ["ireland", "republic of ireland", "eire", "éire"]),
            ("us", ["united states", "u.s.", "usa", "america", "the states"]),
            ("canada", ["canada"]),
            ("australia", ["australia"]),
            ("new_zealand", ["new zealand", "nz", "n.z."]),
            ("france", ["france"]),
            ("germany", ["germany"]),
            ("spain", ["spain"]),
            ("italy", ["italy"]),
            ("netherlands", ["netherlands", "holland"]),
            ("sweden", ["sweden"]),
            ("norway", ["norway"]),
            ("denmark", ["denmark"]),
            ("switzerland", ["switzerland"]),
            ("austria", ["austria"]),
            ("belgium", ["belgium"]),
            ("portugal", ["portugal"]),
            ("greece", ["greece"]),
            ("poland", ["poland"]),
            ("czechia", ["czech republic", "czechia"]),
            ("hungary", ["hungary"]),
            ("romania", ["romania"]),
            ("bulgaria", ["bulgaria"]),
            ("turkey", ["turkey"]),
            ("ukraine", ["ukraine"]),
            ("russia", ["russia"]),
            ("israel", ["israel"]),
            ("uae", ["uae", "u.a.e.", "united arab emirates", "dubai", "abu dhabi"]),
            ("saudi", ["saudi", "saudi arabia"]),
            ("egypt", ["egypt"]),
            ("south_africa", ["south africa"]),
            ("nigeria", ["nigeria"]),
            ("kenya", ["kenya"]),
            ("ghana", ["ghana"]),
            ("india", ["india"]),
            ("pakistan", ["pakistan"]),
            ("bangladesh", ["bangladesh"]),
            ("sri_lanka", ["sri lanka"]),
            ("nepal", ["nepal"]),
            ("bhutan", ["bhutan"]),
            ("china", ["china"]),
            ("hong_kong", ["hong kong"]),
            ("taiwan", ["taiwan"]),
            ("south_korea", ["south korea", "korea"]),
            ("singapore", ["singapore"]),
            ("malaysia", ["malaysia"]),
            ("indonesia", ["indonesia"]),
            ("thailand", ["thailand"]),
            ("vietnam", ["vietnam"]),
            ("philippines", ["philippines"]),
            ("japan", ["japan"]),
            ("mongolia", ["mongolia"]),
            ("tibet", ["tibet"])
        ]

        func matchesFirstPersonLocation(_ token: String) -> Bool {
            let t = escapeRegex(Self.normalise(token))
            guard !t.isEmpty else { return false }

            // Explicit first-person anchored forms.
            // Also catches: "im 50 from england"
            let patterns = [
                #"(?<![a-z])im\b.{0,30}\bfrom\s+\#(t)\b"#,
                #"(?<![a-z])i am\b.{0,30}\bfrom\s+\#(t)\b"#,
                #"(?<![a-z])im\b.{0,30}\bin\s+\#(t)\b"#,
                #"(?<![a-z])i am\b.{0,30}\bin\s+\#(t)\b"#,
                #"(?<![a-z])i live\b.{0,10}\bin\s+\#(t)\b"#,
                #"(?<![a-z])im\b.{0,30}\bbased in\s+\#(t)\b"#,
                #"(?<![a-z])i am\b.{0,30}\bbased in\s+\#(t)\b"#,
                #"(?<![a-z])i was born\b.{0,10}\bin\s+\#(t)\b"#,
                #"(?<![a-z])born\b.{0,6}\bin\s+\#(t)\b"#,
                #"(?<![a-z])i grew up\b.{0,10}\bin\s+\#(t)\b"#,
                #"(?<![a-z])i moved\b.{0,10}\bto\s+\#(t)\b"#,
                #"(?<![a-z])i moved back\b.{0,10}\bto\s+\#(t)\b"#
            ]

            return patterns.contains(where: { containsRegex($0, in: text) })
        }

        for (key, aliases) in countries {
            if aliases.contains(where: { matchesFirstPersonLocation($0) }) {
                add("profile:country:\(key)", 0.36)
                break
            }
        }

        // Region (explicit, anchored)
        if hitAny([
            "im in europe", "i am in europe",
            "i live in europe", "im based in europe", "i am based in europe",
            "im from europe", "i am from europe"
        ]) {
            add("profile:region:europe", 0.32)
        }

        // --- Residence history (explicit, anchored)
        // Example: "I lived in India for 12 years" -> profile:residence_long_term:india
        //
        // Widened patterns (text is already normalised).
        let livedRegexes = [
            #"i lived in ([a-z ]{2,}) for (\d{1,2}) years"#,
            #"lived in ([a-z ]{2,}) for (\d{1,2}) years"#,
            #"i lived in ([a-z ]{2,}) for (\d{1,2}) year"#,
            #"lived in ([a-z ]{2,}) for (\d{1,2}) year"#
        ]

        let residenceAliases: [(String, [String])] = [
            ("uk", ["uk", "united kingdom", "britain", "england", "scotland", "wales", "northern ireland"]),
            ("india", ["india"]),
            ("nepal", ["nepal"]),
            ("japan", ["japan"]),
            ("china", ["china"]),
            ("hong_kong", ["hong kong"]),
            ("taiwan", ["taiwan"]),
            ("tibet", ["tibet"])
        ]

        func residenceKey(from captured: String) -> String? {
            let c = captured.trimmingCharacters(in: .whitespacesAndNewlines)
            let cn = Self.normalise(c)
            for (key, aliases) in residenceAliases {
                if aliases.contains(where: { cn.contains(Self.normalise($0)) }) {
                    return key
                }
            }
            return nil
        }

        for p in livedRegexes {
            if let r = try? NSRegularExpression(pattern: p),
               let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               m.numberOfRanges >= 3,
               let cRange = Range(m.range(at: 1), in: text),
               let yRange = Range(m.range(at: 2), in: text),
               let years = Int(text[yRange]) {

                let capturedCountry = String(text[cRange])
                if let key = residenceKey(from: capturedCountry) {
                    if years >= 3 {
                        add("profile:residence_long_term:\(key)", 0.34)
                    } else {
                        add("profile:residence:\(key)", 0.32)
                    }
                }
                break
            }
        }

        // --- Languages (explicit, simple, broader than "i speak X")
        let languageRegexes: [(String, [String])] = [
            ("tibetan", [
                #"(?<![a-z])i speak\b.{0,12}\btibetan\b"#,
                #"(?<![a-z])i can speak\b.{0,12}\btibetan\b"#,
                #"(?<![a-z])i understand\b.{0,12}\btibetan\b"#,
                #"(?<![a-z])i can read\b.{0,12}\btibetan\b"#,
                #"(?<![a-z])some tibetan\b"#,
                #"(?<![a-z])a bit of tibetan\b"#
            ]),
            ("japanese", [
                #"(?<![a-z])i speak\b.{0,12}\bjapanese\b"#,
                #"(?<![a-z])i can speak\b.{0,12}\bjapanese\b"#,
                #"(?<![a-z])i understand\b.{0,12}\bjapanese\b"#,
                #"(?<![a-z])i can read\b.{0,12}\bjapanese\b"#,
                #"(?<![a-z])some japanese\b"#,
                #"(?<![a-z])a bit of japanese\b"#
            ]),
            ("hindi", [
                #"(?<![a-z])i speak\b.{0,12}\bhindi\b"#,
                #"(?<![a-z])i can speak\b.{0,12}\bhindi\b"#,
                #"(?<![a-z])i understand\b.{0,12}\bhindi\b"#,
                #"(?<![a-z])some hindi\b"#,
                #"(?<![a-z])a bit of hindi\b"#
            ]),
            ("chinese", [
                #"(?<![a-z])i speak\b.{0,12}\bchinese\b"#,
                #"(?<![a-z])i speak\b.{0,12}\bmandarin\b"#,
                #"(?<![a-z])i speak\b.{0,12}\bcantonese\b"#,
                #"(?<![a-z])i understand\b.{0,12}\bmandarin\b"#,
                #"(?<![a-z])i understand\b.{0,12}\bcantonese\b"#,
                #"(?<![a-z])some mandarin\b"#,
                #"(?<![a-z])some cantonese\b"#
            ])
        ]

        for (lang, patterns) in languageRegexes {
            if patterns.contains(where: { containsRegex($0, in: text) }) {
                add("profile:language:\(lang)", 0.32)
            }
        }

        // --- Age (explicit numeric patterns only)
        // Store age band + decade (avoid exact unless you later decide otherwise).
        func ageBandKey(for age: Int) -> String {
            switch age {
            case 0..<18: return "under_18"
            case 18..<25: return "18_24"
            case 25..<35: return "25_34"
            case 35..<45: return "35_44"
            case 45..<55: return "45_54"
            case 55..<65: return "55_64"
            case 65..<75: return "65_74"
            default: return "75_plus"
            }
        }
        func ageDecadeKey(for age: Int) -> String {
            let d = (age / 10) * 10
            return "\(d)s"
        }

        let agePatterns = [
            #"(?<![a-z])i[' ]?m\s+(\d{1,2})\b"#,
            #"(?<![a-z])i\s+am\s+(\d{1,2})\b"#,
            #"(?<![a-z])(\d{1,2})\s+years\s+old\b"#,
            #"(?<![a-z])aged\s+(\d{1,2})\b"#
        ]
        for p in agePatterns {
            if let r = try? NSRegularExpression(pattern: p),
               let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               m.numberOfRanges >= 2,
               let range = Range(m.range(at: 1), in: text),
               let age = Int(text[range]),
               (18...99).contains(age) {
                add("profile:age_band:\(ageBandKey(for: age))", 0.34)
                add("profile:age_decade:\(ageDecadeKey(for: age))", 0.32)
                break
            }
        }

        // Avoid flooding
        return Array(out.prefix(12))
    }

    // MARK: NEW — Dharma milestones (explicit phrases only; no inference)
    private func deriveDharmaMilestones(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        // Keep >= 0.30 so it can persist if LearningSync thresholds apply.
        func add(_ key: String, _ strength: Double = 0.36) {
            out.append(.init(kind: .topic_recurrence, key: key, strength: strength))
        }

        func hitAny(_ phrases: [String]) -> Bool {
            phrases.contains(where: { text.contains($0) })
        }

        // --- Ordination / roles (explicit)
        // Widened: catch "im an ordained ngakpa" and also allow plain "ngakpa" mentions.
        let roles: [(String, [String])] = [
            ("ordained", ["i am ordained", "im ordained", "i was ordained"]),
            ("ngakpa", [
                "ngakpa",
                "ordained ngakpa",
                "im an ordained ngakpa",
                "i am an ordained ngakpa",
                "im a ngakpa",
                "i am a ngakpa",
                "ngakpa ordained"
            ]),
            ("monastic", ["i am a monk", "im a monk", "i am a nun", "im a nun", "monastic"])
        ]
        for (k, phrases) in roles where hitAny(phrases) {
            add("dharma:milestone:role:\(k)")
        }

        // --- Retreats (explicit)
        if hitAny(["three year retreat", "3 year retreat", "three-year retreat", "3-year retreat"]) {
            add("dharma:milestone:retreat:three_year")
        }
        if hitAny(["one year retreat", "1 year retreat", "one-year retreat", "1-year retreat"]) {
            add("dharma:milestone:retreat:one_year", 0.34)
        }
        if hitAny(["retreat master", "retreatant", "in retreat", "on retreat"]) {
            add("dharma:milestone:retreat:has_retreat_history", 0.32)
        }

        // --- Study duration (explicit numeric only)
        // Widened (text is already normalised).
        let studyPatterns = [
            #"studied .* for (\d{1,2}) years"#,
            #"trained .* for (\d{1,2}) years"#,
            #"practiced .* for (\d{1,2}) years"#,
            #"been practicing .* for (\d{1,2}) years"#
        ]
        for p in studyPatterns {
            if let r = try? NSRegularExpression(pattern: p),
               let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               m.numberOfRanges >= 2,
               let range = Range(m.range(at: 1), in: text),
               let years = Int(text[range]) {

                let band: String
                switch years {
                case 0..<3: band = "0_2y"
                case 3..<7: band = "3_6y"
                case 7..<15: band = "7_14y"
                case 15..<25: band = "15_24y"
                default: band = "25y_plus"
                }
                add("dharma:milestone:study_years:\(band)", 0.34)
                break
            }
        }

        // --- Degrees / formal titles (explicit)
        let credentials: [(String, [String])] = [
            ("geshe", ["geshe degree", "i am a geshe", "im a geshe", "completed geshe", "finished geshe"]),
            ("khenpo", ["khenpo", "i am a khenpo", "im a khenpo"]),
            ("phd_philosophy", [
                "phd in philosophy",
                "ph d in philosophy",
                "ph.d. in philosophy",
                "doctorate in philosophy",
                "i have a phd in philosophy"
            ]),
            ("phd_buddhist_studies", [
                "phd in buddhist studies",
                "ph d in buddhist studies",
                "ph.d. in buddhist studies",
                "doctorate in buddhist studies"
            ]),
            ("ma_philosophy", ["masters in philosophy", "master's in philosophy", "ma in philosophy"]),
            ("ma_buddhist_studies", ["masters in buddhist studies", "master's in buddhist studies", "ma in buddhist studies"])
        ]
        for (k, phrases) in credentials where hitAny(phrases) {
            add("dharma:milestone:credential:\(k)", 0.34)
        }

        return Array(out.prefix(8))
    }

    // MARK: NEW — Buddhist practice signals (explicit phrases only; no inference)
    private func deriveBuddhistSignals(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        // IMPORTANT: keep >= 0.30 so it can persist if LearningSync thresholds apply.
        func add(_ key: String, _ strength: Double = 0.34) {
            out.append(.init(kind: .topic_recurrence, key: key, strength: strength))
        }

        func hitAny(_ phrases: [String]) -> Bool {
            phrases.contains(where: { text.contains($0) })
        }

        // --- Vehicles / broad frames (explicit; include contested terms as user-said tokens)
        let vehicles: [(String, [String])] = [
            ("theravada", ["theravada", "theravāda"]),
            ("mahayana", ["mahayana", "mahāyāna", "mahayaana", "mahayana buddhism"]),
            ("vajrayana", ["vajrayana", "vajrayāna", "tantra", "tantric", "i practice tantra", "diamond vehicle", "vajra vehicle"]),
            ("hinayana_term", ["hinayana", "hīnayāna"]), // store as "term used" not endorsement
            ("sutrayana", ["sutra", "sūtra", "sutrayana", "sūtrayāna", "i practice sutra"]),
            ("zen", ["zen", "chan", "soto", "rinzai", "seon"]),
            ("pure_land", ["pure land", "jodo", "jōdo", "jodo shinshu", "shin buddhism", "amitabha", "amitābha", "nembutsu", "nenbutsu"]),
            ("tibetan", ["tibetan buddhism", "tibetan", "vajrayana", "tantra"]),
            ("secular", ["secular buddhism", "secular dharma"])
        ]
        for (k, phrases) in vehicles where hitAny(phrases) {
            add("dharma:vehicle:\(k)", 0.35)
        }

        // --- Tibetan schools / lineages (explicit)
        let schools: [(String, [String])] = [
            ("nyingma", ["nyingma"]),
            ("kagyu", ["kagyu", "kagyü", "karma kagyu", "drukpa kagyu"]),
            ("gelug", ["gelug", "geluk", "gelugpa", "gelukpa", "fpmt"]),
            ("sakya", ["sakya", "sakyapa"]),
            ("jonang", ["jonang"]),
            ("bon", ["bön", "bon"])
        ]
        for (k, phrases) in schools where hitAny(phrases) {
            add("dharma:school:\(k)", 0.35)
        }

        // --- Roles (explicit; spelling variants)
        let roles: [(String, [String])] = [
            ("monastic", ["im ordained", "i am ordained", "monastic", "monk", "nun", "bhikkhu", "bhikkhuni", "bhikshu", "bhikshuni"]),
            ("lay", ["lay practitioner", "lay buddhist", "householder", "im lay", "i am lay"]),
            ("ngakpa", ["ngakpa", "ngagpa", "sngags pa", "ngakpa ordained", "ordained ngakpa", "im a ngakpa", "i am a ngakpa"]),
            ("teacher_role_terms", ["lama", "rinpoche", "khenpo", "geshe", "roshi", "ajahn", "sayadaw", "teacher", "guru"])
        ]
        for (k, phrases) in roles where hitAny(phrases) {
            add("dharma:role:\(k)", 0.34)
        }

        // --- Experience level (explicit)
        let levels: [(String, [String])] = [
            ("beginner", ["im a beginner", "beginner", "new to buddhism", "new to meditation", "just starting", "starting out"]),
            ("intermediate", ["intermediate", "some experience", "i've practiced a bit", "i have practiced a bit"]),
            ("advanced", ["advanced practitioner", "very experienced", "decades of practice", "long term practitioner", "long-term practitioner", "long time practitioner"]),
            ("long_time", ["for years", "for decades", "many years", "a long time", "over 10 years", "over ten years"])
        ]

        for (k, phrases) in levels where hitAny(phrases) {
            add("dharma:experience:\(k)", 0.34)
        }

        // --- Core practices / forms (explicit)
        let practiceForms: [(String, [String])] = [
            // General meditation
            ("shamatha", ["shamatha", "śamatha", "calm abiding", "calm-abiding", "tranquillity"]),
            ("vipashyana", ["vipashyana", "vipaśyanā", "vipassana", "insight meditation", "insight practice"]),
            ("zazen", ["zazen", "shikantaza"]),
            ("koan", ["koan", "kōan"]),
            ("metta", ["metta", "mettā", "loving-kindness", "loving kindness"]),
            ("tonglen", ["tonglen", "gtong len"]),
            ("lojong", ["lojong", "blo sbyong", "mind training"]),

            // Tibetan / Vajrayana
            ("ngondro", ["ngondro", "ngöndro", "sngon 'gro", "preliminaries"]),
            ("prostrations", ["prostrations", "100 000 prostrations", "100,000 prostrations", "hundred thousand prostrations"]),
            ("mandala_offering", ["mandala offering", "maṇḍala offering", "mandala offerings"]),
            ("refuge", ["refuge", "taking refuge"]),
            ("bodhicitta", ["bodhicitta", "byang chub sems"]),
            ("vajrasattva", ["vajrasattva", "benzo satto", "benza satto", "dorje sempa", "confession", "confessional", "downfall", "samaya", "samaya break", "samaya repair"]),
            ("guru_yoga", ["guru yoga", "lama i naljor", "lama'i naljor", "lama naljor"]),
            ("mantra_recitation", ["mantra recitation", "reciting mantra", "mantra practice", "japa"]),
            ("sadhana", ["sadhana", "sādhana", "daily sadhana", "my daily practice is sadhana"]),
            ("accumulation", ["accumulation", "accumulations", "ngakso", "tsok accumulation", "merit accumulation"]),
            ("tsok", ["tsok", "tshogs", "ganachakra", "gaṇacakra", "feast offering"]),
            ("chöd", ["chod", "chöd", "gcod"]),
            ("phowa", ["phowa", "pho ba"]),
            ("tummo", ["tummo", "gtum mo", "inner heat"]),
            ("completion_stage", ["completion stage", "dzogrim", "rdzogs rim"]),
            ("generation_stage", ["generation stage", "kyerim", "bskyed rim"]),
            ("mahamudra", ["mahamudra", "mahāmudrā"]),
            ("dzogchen", ["dzogchen", "rdzogs chen", "atiyoga", "trekchö", "trekcho", "thögal", "thogal", "rigpa"]),
            ("trekcho", ["trekchö", "trekcho", "cutting through"]),
            ("thogal", ["thögal", "thogal", "direct crossing"]),
            ("ngondro_complete", [
                "completed ngondro",
                "completed ngöndro",
                "finished ngondro",
                "finished ngöndro",
                "i completed ngondro",
                "i completed ngöndro",
                "i finished ngondro",
                "i finished ngöndro",
                "i have completed ngondro",
                "i have completed ngöndro",
                "i did ngondro",
                "i have done ngondro",
                "i have done ngöndro",
                "completed the preliminaries",
                "finished the preliminaries",
                "done the preliminaries"
            ]),

            // Objects / arts
            ("thangka", ["thangka", "thangka painting", "thangka practice"])
        ]
        for (k, phrases) in practiceForms where hitAny(phrases) {
            add("dharma:practice:\(k)", 0.35)
        }

        // --- Deity / yidam / Buddha figure mentions (explicit)
        // Store as practice-affinity tags; do not infer empowerment/commitment.
        let deities: [(String, [String])] = [
            ("tara", ["tara", "tārā"]),
            ("green_tara", ["green tara", "syamatara", "śyāmatārā"]),
            ("white_tara", ["white tara", "sitatara", "sitatārā"]),
            ("medicine_buddha", ["medicine buddha", "bhaishajyaguru", "bhaiṣajyaguru", "sangye menla", "menla"]),
            ("avalokiteshvara", ["avalokiteshvara", "avalokiteśvara", "chenrezig", "chenrezi", "guanyin", "kannon"]),
            ("manjushri", ["manjushri", "mañjuśrī", "manjushree", "jamyang", "jam dbyangs"]),
            ("vajrapani", ["vajrapani", "vajrapāṇi", "chana dorje", "phyag na rdo rje"]),
            ("padmasambhava", ["padmasambhava", "guru rinpoche", "guru rimpoche", "orhyen", "orgyen", "uru gyen", "oddiyana", "oḍḍiyāna"]),
            ("amitabha", ["amitabha", "amitābha"]),
            ("shakyamuni", ["shakyamuni", "śākyamuni"]),
            ("vajrayogini", ["vajrayogini", "vajrayoginī", "dorje naljorma"]),
            ("yeshe_tsogyal", ["yeshe tsogyal", "ye shes mtsho rgyal"]),
            ("vajrakilaya", ["vajrakilaya", "vajrakīlāya", "phurba", "phur pa", "kilaya"]),
            ("hevajra", ["hevajra"]),
            ("chakrasamvara", ["chakrasamvara", "cakrasaṃvara", "heruka", "khorlo demchok", "demchok"]),
            ("yamantaka", ["yamantaka", "vajrabhairava"]),
            ("kalachakra", ["kalachakra", "kālacakra"])
        ]
        for (k, phrases) in deities where hitAny(phrases) {
            add("dharma:deity:\(k)", 0.35)
        }

        // --- Ritual / textual terms (explicit)
        let ritualTerms: [(String, [String])] = [
            ("sutra_term", ["sutra", "sūtra"]),
            ("tantra_term", ["tantra", "tantric"]),
            ("mantra_term", ["mantra", "dharani", "dhāraṇī"]),
            ("empowerment_term", ["empowerment", "wang", "dbang", "lung", "reading transmission", "tri", "instruction"]),
            ("samaya_term", ["samaya", "damtsig", "dam tshig"]),
            ("confession_term", ["confession", "confessional", "downfall", "purification", "purify", "purifying"])
        ]
        for (k, phrases) in ritualTerms where hitAny(phrases) {
            add("dharma:term:\(k)", 0.32)
        }

        // Avoid flooding
        return Array(out.prefix(18))
    }

    // MARK: - Apply

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

        let hlPolicy = halfLifeDays(for: kind, key: keyValue)

        if let row = matches.first {
            let hl = max(1.0, hlPolicy)
            let deltaDays = max(0, now.timeIntervalSince(row.lastSeenAt) / (60 * 60 * 24))
            let decayFactor = pow(0.5, deltaDays / hl)

            let decayed = row.score * decayFactor

            // Allow negative increments for explicit deactivation.
            // Clamp score into [0,1].
            row.score = min(1.0, max(0.0, decayed + increment))
            row.count &+= 1
            row.lastSeenAt = now
            row.halfLifeDays = hlPolicy
        } else {
            // Don't create rows from deactivations.
            guard increment > 0 else { return }

            let row = PatternStatsEntity(
                kindRaw: kindRaw,
                key: keyValue,
                score: min(1.0, max(0.0, increment)),
                count: 1,
                firstSeenAt: now,
                lastSeenAt: now,
                halfLifeDays: hlPolicy
            )
            context.insert(row)
        }
    }
}

