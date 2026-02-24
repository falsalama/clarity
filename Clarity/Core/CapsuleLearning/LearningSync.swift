import Foundation
import SwiftData

@MainActor
struct LearningSync {

    static func sync(context: ModelContext, capsuleStore: CapsuleStore, now: Date = Date()) {
        do {
            var rows = try context.fetch(FetchDescriptor<PatternStatsEntity>())

            // Suppress any stats observed at/before the last reset
            if let resetAt = capsuleStore.capsule.learningResetAt {
                rows = rows.filter { $0.lastSeenAt > resetAt }
            }

            // Exclude specific keys we don't want to surface
            rows = rows.filter { !($0.kind == .constraint_trigger && $0.key == "trigger:eye_contact") }

            // Thresholds (per-kind + per-key overrides)
            rows = rows.filter { r in
                switch r.kind {
                case .constraints_sensitivity:
                    // Delicate cues: require stronger score and at least two observations
                    return r.score >= 0.6 && r.count >= 2

                case .workflow_preference:
                    // New explicit-phrase v1 cues: require at least two observations and score >= 0.4
                    if ["question_light", "question_guided", "narrow_first", "explore_space"].contains(r.key) {
                        return r.score >= 0.4 && r.count >= 2
                    }
                    return r.score >= 0.3

                default:
                    return r.score >= 0.3
                }
            }

            // MARK: Persistence bucketing (sticky / seasonal / ephemeral)

            enum Bucket { case sticky, seasonal, ephemeral }

            func daysSince(_ date: Date) -> Double {
                max(0, now.timeIntervalSince(date) / (60 * 60 * 24))
            }

            // Ephemeral window: only surface "today-ish" states when genuinely recent.
            let ephemeralRecencyDays: Double = 7.0

            func bucket(for r: PatternStatsEntity) -> Bucket {
                // Ephemeral: day-state and short-lived ease signals
                if r.kind == .release_pattern { return .ephemeral }
                if r.kind == .constraint_trigger {
                    if r.key.contains("low_sleep") || r.key.contains("low_energy") || r.key.contains("deadline_pressure") {
                        return .ephemeral
                    }
                }
                if r.kind == .constraints_sensitivity {
                    // treat time/energy as potentially ephemeral; other constraints are longer-lived
                    if r.key == "time_pressure" || r.key == "low_energy" {
                        return .ephemeral
                    }
                }

                // Sticky: environment/sensory/social triggers + certain hard workflow prefs
                if r.kind == .constraint_trigger { return .sticky }
                if r.kind == .constraints_sensitivity, r.key == "sensory_noise" { return .sticky }
                if r.kind == .workflow_preference, r.key == "question_light" { return .sticky }

                // Seasonal: everything else (preferences and patterns that can evolve)
                return .seasonal
            }

            // Extra gating for ephemeral: must be recent + slightly higher bar to avoid noise.
            rows = rows.filter { r in
                let b = bucket(for: r)
                guard b == .ephemeral else { return true }

                // Recency gate
                guard daysSince(r.lastSeenAt) <= ephemeralRecencyDays else { return false }

                // Strength gate (a bit stricter than default)
                switch r.kind {
                case .release_pattern:
                    return r.score >= 0.4
                case .constraint_trigger:
                    // e.g. low_sleep / low_energy / deadline_pressure
                    return r.score >= 0.5 && r.count >= 2
                case .constraints_sensitivity:
                    // time_pressure / low_energy
                    return r.score >= 0.6 && r.count >= 2
                default:
                    return r.score >= 0.5
                }
            }

            // Sort: score desc, then lastSeenAt desc (global pre-sort)
            rows.sort {
                if $0.score == $1.score {
                    return $0.lastSeenAt > $1.lastSeenAt
                }
                return $0.score > $1.score
            }

            // MARK: Lane budgets (inject a little; keep learning broad)

            let stickyCap = 8
            let seasonalCap = 10
            let ephemeralCap = 4
            let globalCap = 24

            // Optional diversity cap per kind within each lane
            let maxPerKindWithinLane = 6

            func select(from candidates: [PatternStatsEntity], cap: Int) -> [PatternStatsEntity] {
                guard cap > 0, !candidates.isEmpty else { return [] }

                // Group by kind for diversity
                var perKind: [PatternStatsEntity.Kind: [PatternStatsEntity]] = [:]
                for r in candidates {
                    perKind[r.kind, default: []].append(r)
                }
                for (k, arr) in perKind {
                    let sorted = arr.sorted {
                        if $0.score == $1.score { return $0.lastSeenAt > $1.lastSeenAt }
                        return $0.score > $1.score
                    }
                    perKind[k] = Array(sorted.prefix(maxPerKindWithinLane))
                }

                // Flatten and cap
                var flattened: [PatternStatsEntity] = perKind.values.flatMap { $0 }
                flattened.sort {
                    if $0.score == $1.score { return $0.lastSeenAt > $1.lastSeenAt }
                    return $0.score > $1.score
                }
                return Array(flattened.prefix(cap))
            }

            let stickyRows = rows.filter { bucket(for: $0) == .sticky }
            let seasonalRows = rows.filter { bucket(for: $0) == .seasonal }
            let ephemeralRows = rows.filter { bucket(for: $0) == .ephemeral }

            let chosenSticky = select(from: stickyRows, cap: stickyCap)
            let chosenSeasonal = select(from: seasonalRows, cap: seasonalCap)
            let chosenEphemeral = select(from: ephemeralRows, cap: ephemeralCap)


            // Global cap safety (should not usually trip, but keep deterministic)
            var combined: [PatternStatsEntity] = chosenSticky + chosenSeasonal + chosenEphemeral
            if combined.count > globalCap {
                combined.sort {
                    if $0.score == $1.score { return $0.lastSeenAt > $1.lastSeenAt }
                    return $0.score > $1.score
                }
                combined = Array(combined.prefix(globalCap))
                // re-split not required; we only use combined from here
            } else {
                // Keep presentation order: sticky -> seasonal -> ephemeral
                combined = chosenSticky + chosenSeasonal + chosenEphemeral
            }

            // Map to curated tendencies
            let projected: [CapsuleTendency] = combined.map { r in
                CapsuleTendency(
                    id: UUID(),
                    statement: statement(for: r.kind, key: r.key),
                    evidenceCount: r.count,
                    firstSeenAt: r.firstSeenAt,
                    lastSeenAt: r.lastSeenAt,
                    isOverridden: false,
                    sourceKindRaw: r.kind.rawValue,
                    sourceKey: r.key
                )
            }

            // Idempotent write: compare ignoring IDs
            let current = capsuleStore.capsule.learnedTendencies
            if !equalIgnoringIDs(current, projected) {
                capsuleStore.setLearnedTendencies(projected)
            }
        } catch {
            // Silent by design
        }
    }

    static func wipeAllStats(context: ModelContext) {
        do {
            let all = try context.fetch(FetchDescriptor<PatternStatsEntity>())
            for row in all {
                context.delete(row)
            }
            try context.save()
        } catch {
            // Silent by design
        }
    }

    private static func statement(for kind: PatternStatsEntity.Kind, key: String) -> String {
        let k = key.replacingOccurrences(of: "_", with: " ")
        switch kind {
        case .style_preference:
            switch key {
            case "bullets": return "Prefers bullet points"
            case "concise": return "Prefers concise summaries"
            case "scripted_reply": return "Often wants suggested wording"
            case "prefers_tldr_then_detail": return "Prefers TL;DR first, then details"
            case "prefers_brief": return "Prefers brief answers"
            case "prefers_numbered_steps": return "Prefers numbered steps"
            case "prefers_checklist": return "Prefers checklists"
            case "prefers_decision_tree": return "Prefers decision trees"
            case "prefers_no_fluff": return "Prefers direct, no-fluff replies"
            default: return "Prefers \(k)"
            }

        case .workflow_preference:
            switch key {
            case "options_first": return "Wants options before questions"
            case "prefers_confirm_then_execute": return "Prefers to confirm once, then proceed"
            case "prefers_execute_immediately": return "Prefers to execute without preamble"
            case "prefers_just_answer": return "Prefers a direct answer"
            case "prefers_few_questions": return "Prefers fewer questions"
            case "prefers_no_clarifying_questions": return "Prefers no clarifying questions"

            // New explicit-phrase v1 cues
            case "question_light": return "Prefers lighter questioning"
            case "question_guided": return "Prefers guided questioning"
            case "narrow_first": return "Prefers one path first"
            case "explore_space": return "Prefers exploring options"

            default: return "Often wants \(k)"
            }

        case .topic_recurrence:

            func human(_ raw: String) -> String {
                raw.replacingOccurrences(of: "_", with: " ")
            }

            func tail(after prefix: String) -> String {
                String(key.dropFirst(prefix.count))
            }

            if key.hasPrefix("topic:") {
                return "Topic: \(human(tail(after: "topic:")))"
            }

            if key.hasPrefix("dharma:practice:") {
                return "Practises \(human(tail(after: "dharma:practice:")))"
            }
            if key.hasPrefix("dharma:vehicle:") {
                return "Vehicle: \(human(tail(after: "dharma:vehicle:")))"
            }
            if key.hasPrefix("dharma:lineage:") {
                return "Lineage: \(human(tail(after: "dharma:lineage:")))"
            }
            if key.hasPrefix("dharma:level:") {
                return "Practice level: \(human(tail(after: "dharma:level:")))"
            }
            if key.hasPrefix("dharma:training:") {
                return "Training: \(human(tail(after: "dharma:training:")))"
            }
            if key.hasPrefix("dharma:aim:") {
                return "Aim: \(human(tail(after: "dharma:aim:")))"
            }

            if key.hasPrefix("profile:language:") {
                return "Language: \(human(tail(after: "profile:language:")))"
            }
            if key.hasPrefix("profile:country:") {
                return "Country: \(human(tail(after: "profile:country:")))"
            }
            if key.hasPrefix("profile:region:") {
                return "Region: \(human(tail(after: "profile:region:")))"
            }

            // Safe fallback (neutral)
            return "Noted: \(human(key))"


        case .resolution_pattern:
            switch key {
            case "constraints_first": return "Responds better when constraints are addressed early"
            case "decision_stuck": return "Gets stuck deciding under uncertainty"
            case "needs_decompression": return "Responds better after decompressing first"
            case "complexity_high": return "Often faces high complexity"
            case "prefers_reframe_then_steps": return "Responds better with a reframe before steps"
            default: return "Responds better when \(k)"
            }

        case .constraints_sensitivity:
            switch key {
            case "time_pressure": return "Often constrained by time pressure"
            case "low_energy": return "Often constrained by low energy"
            case "money_limit": return "Often constrained by money limits"
            case "social_overload": return "Often constrained by social factors"
            case "dependency_blocked": return "Often constrained by dependencies"
            case "sensory_noise": return "Sensitive to sensory overload"
            case "legal_risk": return "Often constrained by legal risk"
            default: return "Often constrained by \(k)"
            }

        case .narrative_pattern:
            switch key {
            case "replay_loop": return "Tends to replay the story"
            case "identity_frame_present": return "Framing often involves identity"
            case "outcome_fixation": return "Fixates on a single outcome"
            case "control_frame": return "Framing leans toward control"
            case "uncertainty_pressure": return "Feels pressure from uncertainty"
            case "self_attack_language": return "Uses self-critical language"
            case "reassurance_checking": return "Seeks reassurance"
            case "avoidance_language": return "Uses avoidance language"
            default: return "Narrative pattern: \(k)"
            }

        case .lens_preference:
            switch key {
            case "softening_helps": return "Softening lens tends to help"
            case "widening_helps": return "Widening lens tends to help"
            case "letting_be_helps": return "Letting-be lens tends to help"
            case "compassionate_witnessing_helps": return "Compassionate witnessing tends to help"
            case "impermanence_helps": return "Impermanence lens tends to help"
            case "non_identification_helps": return "Non-identification lens tends to help"
            default: return "Lens \(k) tends to help"
            }

        case .constraint_trigger:
            // Avoid the word “trigger” in UI; phrase as situational constraints
            switch key {
            case "trigger:noise": return "Often harder in noisy environments"
            case "trigger:bright_light": return "Often harder with bright light"
            case "trigger:crowds": return "Often harder in crowds"
            case "trigger:group_dynamics": return "Often harder with complex group dynamics"
            case "trigger:hierarchy_games": return "Often harder with power dynamics"
            case "trigger:being_observed": return "Often harder when being observed"
            case "trigger:too_many_variables": return "Often harder with many variables"
            case "trigger:unclear_requirements": return "Often harder when requirements are unclear"
            case "trigger:interruptions": return "Often harder with frequent interruptions"
            case "trigger:context_switching": return "Often harder with frequent context switching"
            case "trigger:deadline_pressure": return "Often harder under deadline pressure"
            case "trigger:low_sleep": return "Often harder with low sleep"
            case "trigger:low_energy": return "Often harder with low energy"
            default: return "Often harder when \(k)"
            }

        case .contraction_pattern:
            switch key {
            case "contraction:identity_fixation": return "Identity framing can tighten experience"
            case "contraction:outcome_fixation": return "Outcome fixation can increase pressure"
            case "contraction:control_pressure": return "Control efforts can add pressure"
            case "contraction:uncertainty_pressure": return "Uncertainty can amplify tension"
            case "contraction:mental_looping": return "Mental replay can sustain tightening"
            case "contraction:self_attack": return "Self-critical language can tighten experience"
            case "contraction:checking_for_reassurance": return "Checking for reassurance can sustain tightening"
            case "contraction:avoidance_pressure": return "Avoidance language can increase pressure"
            default: return "Tightening can show up under certain conditions"
            }

        case .release_pattern:
            switch key {
            case "release:ease_present": return "Ease can show up under some conditions"
            case "release:settling": return "Settling can appear at times"
            case "release:openness": return "A sense of space can open when pressure drops"
            default: return "Ease can appear under certain conditions"
            }
        }
    }

    private static func equalIgnoringIDs(_ a: [CapsuleTendency], _ b: [CapsuleTendency]) -> Bool {
        let lhs = normalize(a)
        let rhs = normalize(b)
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { l, r in
            // (String, Int, TimeInterval, TimeInterval, Bool, String?, String?)
            return l.0 == r.0 &&
                   l.1 == r.1 &&
                   l.2 == r.2 &&
                   l.3 == r.3 &&
                   l.4 == r.4 &&
                   l.5 == r.5 &&
                   l.6 == r.6
        }
    }

    private static func normalize(_ arr: [CapsuleTendency])
    -> [(String, Int, TimeInterval, TimeInterval, Bool, String?, String?)] {
        arr
            .map {
                (
                    $0.statement,
                    $0.evidenceCount,
                    $0.firstSeenAt.timeIntervalSince1970,
                    $0.lastSeenAt.timeIntervalSince1970,
                    $0.isOverridden,
                    $0.sourceKindRaw,
                    $0.sourceKey
                )
            }
            .sorted { lhs, rhs in
                if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                if lhs.3 != rhs.3 { return lhs.3 > rhs.3 }
                // stable-ish tie breakers
                if lhs.5 != rhs.5 { return (lhs.5 ?? "") < (rhs.5 ?? "") }
                return (lhs.6 ?? "") < (rhs.6 ?? "")
            }
    }
}
