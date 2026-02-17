import Foundation
import SwiftData

struct PatternObservation: Sendable, Equatable {
    let kind: PatternStatsEntity.Kind
    let key: String
    let strength: Double   // typically -1...1 (positive reinforces, negative deactivates)
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

        // MARK: NEW — Profile signals (explicit phrases only; local redacted text)
        if let text = redactedText?.lowercased(), !text.isEmpty {
            out.append(contentsOf: deriveProfileSignals(from: text))
        }

        // MARK: NEW — Buddhist practice signals (explicit phrases only; no inference)
        if let text = redactedText?.lowercased(), !text.isEmpty {
            out.append(contentsOf: deriveBuddhistSignals(from: text))
        }

        // MARK: NEW — Explicit deactivation phrases (agency-first; no inference)
        if let text = redactedText?.lowercased(), !text.isEmpty {
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

        // Bound per-turn emission to a small, stable set
        return Array(sorted.prefix(12))
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
            "it's fine now",
            "it is fine now",
            "stop doing that",
            "don't do that",
            "do not do that",
            "you can stop",
            "i don't need that",
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

    // MARK: NEW — Profile signals (explicit phrases only)
    private func deriveProfileSignals(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        func add(_ key: String, _ strength: Double = 0.30) {
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
            add("profile:language:english", 0.25)
        }
        if hitAny([
            "english isn't my first language", "english is not my first language", "non-native english", "non native english"
        ]) {
            add("profile:language:non_native_english", 0.25)
        }

        // --- Country / region (explicit phrasing)
        // Store coarse key only.
        let countries: [(String, [String])] = [
            ("uk", ["united kingdom", "u.k.", " uk ", " U.K", "UK", "the uk", "the UK", "the U.K", "the U.K.","britain", "great britain", "england", "scotland", "wales", "northern ireland"]),
            ("ireland", ["ireland", "republic of ireland", "eire", "éire"]),
            ("us", ["united states", "u.s.", " usa ", "in the us", "in the usa", "in america", "in the states"]),
            ("canada", ["canada", "in canada"]),
            ("australia", ["australia", "in australia"]),
            ("new_zealand", ["new zealand", "nz ", "n.z."]),
            ("france", ["france", "in france"]),
            ("germany", ["germany", "in germany"]),
            ("spain", ["spain", "in spain"]),
            ("italy", ["italy", "in italy"]),
            ("netherlands", ["netherlands", "holland", "in the netherlands"]),
            ("sweden", ["sweden", "in sweden"]),
            ("norway", ["norway", "in norway"]),
            ("denmark", ["denmark", "in denmark"]),
            ("switzerland", ["switzerland", "in switzerland"]),
            ("austria", ["austria", "in austria"]),
            ("belgium", ["belgium", "in belgium"]),
            ("portugal", ["portugal", "in portugal"]),
            ("greece", ["greece", "in greece"]),
            ("poland", ["poland", "in poland"]),
            ("czechia", ["czech republic", "czechia", "in czech"]),
            ("hungary", ["hungary", "in hungary"]),
            ("romania", ["romania", "in romania"]),
            ("bulgaria", ["bulgaria", "in bulgaria"]),
            ("turkey", ["turkey", "in turkey"]),
            ("ukraine", ["ukraine", "in ukraine"]),
            ("russia", ["russia", "in russia"]),
            ("israel", ["israel", "in israel"]),
            ("uae", ["uae", "u.a.e.", "united arab emirates", "in dubai", "in abu dhabi"]),
            ("saudi", ["saudi", "saudi arabia", "in saudi"]),
            ("egypt", ["egypt", "in egypt"]),
            ("south_africa", ["south africa", "in south africa"]),
            ("nigeria", ["nigeria", "in nigeria"]),
            ("kenya", ["kenya", "in kenya"]),
            ("ghana", ["ghana", "in ghana"]),
            ("india", ["india", "in india"]),
            ("pakistan", ["pakistan", "in pakistan"]),
            ("bangladesh", ["bangladesh", "in bangladesh"]),
            ("sri_lanka", ["sri lanka", "in sri lanka"]),
            ("nepal", ["nepal", "in nepal"]),
            ("bhutan", ["bhutan", "in bhutan"]),
            ("china", ["china", "in china"]),
            ("hong_kong", ["hong kong", "in hong kong"]),
            ("taiwan", ["taiwan", "in taiwan"]),
            ("south_korea", ["south korea", "korea", "in korea"]),
            ("singapore", ["singapore", "in singapore"]),
            ("malaysia", ["malaysia", "in malaysia"]),
            ("indonesia", ["indonesia", "in indonesia"]),
            ("thailand", ["thailand", "in thailand"]),
            ("vietnam", ["vietnam", "in vietnam"]),
            ("philippines", ["philippines", "in the philippines"]),
            ("japan", ["japan", "in japan"]),
            ("mongolia", ["mongolia", "in mongolia"]),
            ("tibet", ["tibet", "in tibet"])
        ]

        func explicitInPattern(_ token: String) -> Bool {
            // Requires first-person anchor (prevents “France is nice” etc.)
            // Note: token should already be a phrase like "france", "the uk", "united kingdom", "england", etc.
            let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return false }

            let patterns = [
                "i'm in \(t)",
                "i am in \(t)",
                "i live in \(t)",
                "i'm based in \(t)",
                "i am based in \(t)",
                "based in \(t)",
                "i'm from \(t)",
                "i am from \(t)",
                "i was born in \(t)",
                "born in \(t)",
                "i moved to \(t)",
                "i moved back to \(t)",
                "i grew up in \(t)"
            ]

            return patterns.contains(where: { text.contains($0) })
        }

        for (key, phrases) in countries {
            // IMPORTANT: do NOT use hitAny(phrases) here.
            if phrases.contains(where: { explicitInPattern($0) }) {
                add("profile:country:\(key)", 0.25)
                break
            }
        }

        // Region (explicit, anchored)
        let europeAnchors = [
            "i'm in europe", "i am in europe", "im in europe",
            "i live in europe", "i'm based in europe", "i am based in europe",
            "i'm from europe", "i am from europe"
        ]
        if europeAnchors.contains(where: { text.contains($0) }) {
            add("profile:region:europe", 0.20)
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
            #"i[' ]?m\s+(\d{1,2})\b"#,
            #"i\s+am\s+(\d{1,2})\b"#,
            #"(\d{1,2})\s+years\s+old"#,
            #"aged\s+(\d{1,2})\b"#
        ]
        for p in agePatterns {
            if let r = try? NSRegularExpression(pattern: p),
               let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               m.numberOfRanges >= 2,
               let range = Range(m.range(at: 1), in: text),
               let age = Int(text[range]),
               (18...99).contains(age) {
                add("profile:age_band:\(ageBandKey(for: age))", 0.25)
                add("profile:age_decade:\(ageDecadeKey(for: age))", 0.20)
                break
            }
        }

        // Avoid flooding
        return Array(out.prefix(6))
    }

    // MARK: NEW — Buddhist practice signals (explicit phrases only; no inference)
    private func deriveBuddhistSignals(from text: String) -> [PatternObservation] {
        var out: [PatternObservation] = []

        func add(_ key: String, _ strength: Double = 0.30) {
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
            ("monastic", ["i'm ordained", "i am ordained", "monastic", "monk", "nun", "bhikkhu", "bhikkhuni", "bhikshu", "bhikshuni"]),
            ("lay", ["lay practitioner", "lay buddhist", "householder", "i'm lay", "i am lay"]),
            ("ngakpa", ["ngakpa", "ngagpa", "sngags pa", "ngakpa ordained", "ordained ngakpa", "i'm a ngakpa", "i am a ngakpa"]),
            ("teacher_role_terms", ["lama", "rinpoche", "khenpo", "geshe", "roshi", "ajahn", "sayadaw", "teacher", "guru"])
        ]
        for (k, phrases) in roles where hitAny(phrases) {
            add("dharma:role:\(k)", 0.30)
        }

        // --- Experience level (explicit)
        let levels: [(String, [String])] = [
            ("beginner", ["i'm a beginner", "im a beginner", "beginner", "new to buddhism", "new to meditation", "just starting", "starting out"]),
            ("intermediate", ["intermediate", "some experience", "i've practiced a bit", "i have practiced a bit"]),
            ("advanced", ["advanced practitioner", "very experienced", "decades of practice", "long-term practitioner", "long time practitioner"]),
            ("long_time", ["for years", "for decades", "many years", "a long time", "since i was", "over 10 years", "over ten years"])
        ]
        for (k, phrases) in levels where hitAny(phrases) {
            add("dharma:experience:\(k)", 0.30)
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
            ("prostrations", ["prostrations", "100,000 prostrations", "hundred thousand prostrations"]),
            ("mandala_offering", ["mandala offering", "maṇḍala offering", "mandala offerings"]),
            ("refuge", ["refuge", "taking refuge"]),
            ("bodhicitta", ["bodhicitta", "byang chub sems"]),
            ("vajrasattva", ["vajrasattva", "benzo satto", "benza satto", "dorje sempa", "dorje sempa", "confession", "confessional", "downfall", "samaya", "samaya break", "samaya repair"]),
            ("guru_yoga", ["guru yoga", "lama'i naljor", "lama naljor"]),
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
            ("ngondro_complete", ["completed ngondro", "completed ngöndro", "finished ngondro", "finished ngöndro"]),

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
            ("white_tara", ["white tara", "sitatara", "sitatārā", "sitatārā"]),
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
            ("chakrasamvara", ["chakrasamvara", "cakrasaṃvara", "chakrasamvara", "heruka", "khorlo demchok", "demchok"]),
            ("yamantaka", ["yamantaka", "vajrabhairava", "vajrabhairava"]),
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
            add("dharma:term:\(k)", 0.25)
        }

        // Avoid flooding
        return Array(out.prefix(10))
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

