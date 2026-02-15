import Foundation

struct Lift0Context: Codable, Equatable, Sendable {
    enum Intent: String, Codable, CaseIterable, Sendable {
        case decide, plan, vent, understand, rehearse, debrief, create, unknown
    }
    enum StakeLevel: String, Codable, CaseIterable, Sendable { case low, med, high, unknown }
    enum Urgency: String, Codable, CaseIterable, Sendable { case low, med, high, unknown }
    enum TimeHorizon: String, Codable, CaseIterable, Sendable { case now, today, week, longer, unknown }

    var intent_primary: Intent
    var desired_output: [String]          // steps|options|script|summary|reframe|decision_tree|checklist|questions
    var constraints: [String]             // time|energy|money|social|sensory|legal|dependencies|information
    var stake_level: StakeLevel
    var urgency: Urgency
    var time_horizon: TimeHorizon
}

struct Lift0Extractor {
    func extract(from redactedText: String) -> Lift0Context {
        let text = redactedText.lowercased()
        return Lift0Context(
            intent_primary: inferIntent(text),
            desired_output: inferDesiredOutputs(text),
            constraints: inferConstraints(text),
            stake_level: inferStake(text),
            urgency: inferUrgency(text),
            time_horizon: inferHorizon(text)
        )
    }

    private func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }

    private func inferIntent(_ t: String) -> Lift0Context.Intent {
        if containsAny(t, ["should i", "do i", "choose", "pros and cons", "either/or", "either or", "can't decide"]) { return .decide }
        if containsAny(t, ["how do i", "steps", "plan", "timeline", "what next", "break it down"]) { return .plan }
        if containsAny(t, ["fed up", "can't cope"]) { return .vent }
        if containsAny(t, ["why do i", "make sense of", "pattern", "meaning"]) { return .understand }
        if containsAny(t, ["what should i say", "script", "how to phrase", "meeting", "conversation"]) { return .rehearse }
        if containsAny(t, ["what happened was", "after that", "i keep thinking about what i said"]) { return .debrief }
        if containsAny(t, ["draft", "write", "generate", "design"]) { return .create }
        return .unknown
    }

    private func inferDesiredOutputs(_ t: String) -> [String] {
        var out: [String] = []
        if containsAny(t, ["step by step", "checklist", "actionable", "what next"]) { out.append("steps"); out.append("checklist") }
        if t.contains("options") || t.contains("alternatives") || t.contains("ways to") { out.append("options") }
        if containsAny(t, ["what should i say", "wording", "reply"]) { out.append("script") }
        if t.contains("summarise") || t.contains("tldr") || t.contains("tl;dr") { out.append("summary") }
        if containsAny(t, ["another way to see it", "perspective"]) { out.append("reframe") }
        if t.contains("decision tree") || t.contains("if/then") || t.contains("if then") || t.contains("criteria") { out.append("decision_tree") }
        // De-duplicate and cap
        let dedup = Array(Set(out))
        return Array(dedup.prefix(4))
    }

    private func inferConstraints(_ t: String) -> [String] {
        var out: [String] = []
        if containsAny(t, ["deadline", "tomorrow", "urgent", "no time"]) { out.append("time") }
        if containsAny(t, ["exhausted", "burnt out", "can't face it", "cant face"]) { out.append("energy") }
        if containsAny(t, ["budget", "can't afford", "cant afford"]) { out.append("money") }

        // SOCIAL: broaden to catch "social overwhelm" and common social-stress phrasings
        if containsAny(t, [
            "awkward", "politics", "conflict", "what will they think",
            "social situation", "social situations", "socially overwhelmed", "overwhelmed socially",
            "social overwhelm", "socially draining", "socially drained", "draining socially",
            "crowds", "too many people", "group dynamics", "social dynamics", "being watched", "being observed"
        ]) {
            out.append("social")
        }

        // SENSORY: include overload/overstim variants (not just “overwhelming”)
        if containsAny(t, [
            "noisy", "bright", "overwhelming", "overstimulated", "overstimulating",
            "sensory overload", "overloaded"
        ]) {
            out.append("sensory")
        }

        if containsAny(t, ["waiting on", "blocked", "need approval"]) { out.append("dependencies") }
        // "legal" and "information" as catch-alls
        if t.contains("legal") { out.append("legal") }
        if containsAny(t, ["lack of info", "no information", "missing info", "don't know enough", "dont know enough"]) { out.append("information") }

        let dedup = Array(Set(out))
        return Array(dedup.prefix(6))
    }

    private func inferStake(_ t: String) -> Lift0Context.StakeLevel {
        if containsAny(t, ["career-ending", "catastrophic", "cannot fail", "must not fail"]) { return .high }
        if containsAny(t, ["important", "matters a lot"]) { return .med }
        if containsAny(t, ["not a big deal", "minor"]) { return .low }
        return .unknown
    }

    private func inferUrgency(_ t: String) -> Lift0Context.Urgency {
        if containsAny(t, ["urgent", "asap", "right now", "today"]) { return .high }
        if containsAny(t, ["soon", "this week"]) { return .med }
        if containsAny(t, ["no rush", "whenever"]) { return .low }
        return .unknown
    }

    private func inferHorizon(_ t: String) -> Lift0Context.TimeHorizon {
        if containsAny(t, ["right now", "immediately", "now"]) { return .now }
        if t.contains("today") { return .today }
        if t.contains("this week") || t.contains("next week") { return .week }
        if containsAny(t, ["this month", "later this year", "long term", "long-term", "longer term"]) { return .longer }
        return .unknown
    }
}
