import Foundation

enum CanonicalPrimitive: String, CaseIterable, Sendable {
    case attachment_to_outcome
    case aversion_resistance
    case identity_tightening
    case control_seeking
    case narrative_looping
    case intolerance_of_uncertainty
    case self_judgement
    case reassurance_seeking
}

struct PrimitiveCandidate: Sendable, Equatable {
    let primitive: CanonicalPrimitive
    let score: Int            // 0...100
    let confidence: String    // "low" | "med" | "high"
    let evidence: [String]    // snippets
}

struct PrimitiveCandidateExtractor {
    struct Rule {
        let primitive: CanonicalPrimitive
        let phrases: [String]
        let weight: Int
    }

    // Strong/medium/anti rules derived from spec
    private let strongRules: [Rule] = [
        .init(primitive: .narrative_looping, phrases: ["can't stop thinking", "keep replaying", "going over and over", "stuck in my head", "spiralling"], weight: 25),
        .init(primitive: .identity_tightening, phrases: ["it proves i'm", "it means i'm not", "not cut out for", "says something about me"], weight: 25),
        .init(primitive: .attachment_to_outcome, phrases: ["has to", "must", "need it to go well", "can't let this fail"], weight: 20),
        .init(primitive: .aversion_resistance, phrases: ["can't face", "avoiding", "dread", "don't want to deal with"], weight: 20),
        .init(primitive: .control_seeking, phrases: ["make sure", "prevent", "control", "cover every angle", "perfect plan"], weight: 20),
        .init(primitive: .intolerance_of_uncertainty, phrases: ["need to know", "can't stand not knowing", "until i know i can't relax"], weight: 20),
        .init(primitive: .self_judgement, phrases: ["i'm pathetic", "i'm useless", "what's wrong with me", "i hate myself for", "why can't i just"], weight: 20),
        .init(primitive: .reassurance_seeking, phrases: ["tell me it's ok", "am i overreacting", "is this normal"], weight: 20)
    ]

    private let mediumRules: [Rule] = [
        .init(primitive: .narrative_looping, phrases: ["should have", "if only"], weight: 10),
        .init(primitive: .identity_tightening, phrases: ["always", "never", "everything", "nothing"], weight: 10),
        .init(primitive: .attachment_to_outcome, phrases: ["consequence if", "single outcome"], weight: 15),
        .init(primitive: .aversion_resistance, phrases: ["avoiding it", "putting it off"], weight: 10),
        .init(primitive: .control_seeking, phrases: ["contingency", "every possibility"], weight: 10),
        .init(primitive: .intolerance_of_uncertainty, phrases: ["what if", "unknowns"], weight: 10),
        .init(primitive: .self_judgement, phrases: ["should", "must"], weight: 10),
        .init(primitive: .reassurance_seeking, phrases: ["checking again", "ask again"], weight: 10)
    ]

    private let antiRules: [Rule] = [
        .init(primitive: .narrative_looping, phrases: ["so i'll do", "plan is"], weight: -15),
        .init(primitive: .identity_tightening, phrases: ["need to learn", "that meeting was messy"], weight: -15),
        .init(primitive: .aversion_resistance, phrases: ["i'll do it anyway"], weight: -10),
        .init(primitive: .control_seeking, phrases: ["good enough", "delegate"], weight: -10),
        .init(primitive: .intolerance_of_uncertainty, phrases: ["we'll see", "unknown is fine"], weight: -10),
        .init(primitive: .self_judgement, phrases: ["it's okay", "i can be kind to myself"], weight: -10),
        .init(primitive: .reassurance_seeking, phrases: ["no reassurance", "don't reassure"], weight: -10)
    ]

    func extract(from redactedText: String) -> [PrimitiveCandidate] {
        let t = redactedText.lowercased()
        var scores: [CanonicalPrimitive: Int] = [:]
        var evidence: [CanonicalPrimitive: Set<String>] = [:]

        func apply(_ rules: [Rule]) {
            for r in rules {
                for p in r.phrases {
                    if t.contains(p) {
                        scores[r.primitive, default: 0] += r.weight
                        if r.weight > 0 {
                            var ev = evidence[r.primitive] ?? []
                            ev.insert(p)
                            evidence[r.primitive] = ev
                        }
                    }
                }
            }
        }

        apply(strongRules)
        apply(mediumRules)
        apply(antiRules)

        // structural features
        if t.components(separatedBy: " what if").count - 1 >= 3 {
            scores[.intolerance_of_uncertainty, default: 0] += 8
        }
        if t.components(separatedBy: " if only").count - 1 >= 2 {
            scores[.narrative_looping, default: 0] += 8
        }

        // Clamp 0...100
        for k in CanonicalPrimitive.allCases {
            scores[k] = min(100, max(0, scores[k] ?? 0))
        }

        // Thresholds
        func confidence(for score: Int) -> String {
            if score >= 70 { return "high" }
            if score >= 45 { return "med" }
            return "low"
        }

        var out: [PrimitiveCandidate] = []
        for (primitive, score) in scores where score > 0 {
            let conf = confidence(for: score)
            if score >= 45 { // include background threshold and above
                let ev = Array(evidence[primitive] ?? [])
                out.append(PrimitiveCandidate(primitive: primitive, score: score, confidence: conf, evidence: ev))
            }
        }

        // Sort by score desc
        out.sort { a, b in
            if a.score != b.score { return a.score > b.score }
            return a.primitive.rawValue < b.primitive.rawValue
        }
        return out
    }

    func selectTop(dominantMax: Int = 2, backgroundMax: Int = 1, from candidates: [PrimitiveCandidate]) -> (dominant: [CanonicalPrimitive], background: [CanonicalPrimitive], needsConfirmation: Bool) {
        let dom = candidates.filter { $0.score >= 70 }.map { $0.primitive }
        let bg = candidates.filter { $0.score >= 45 && $0.score < 70 }.map { $0.primitive }

        let chosenDom = Array(dom.prefix(dominantMax))
        let chosenBg = Array(bg.prefix(backgroundMax))

        // If ties/low confidence (no high), ask one confirmation
        let needs = chosenDom.isEmpty && !chosenBg.isEmpty
        return (chosenDom, chosenBg, needs)
    }
}
