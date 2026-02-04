import Foundation

enum CanonicalLens: String, Codable, CaseIterable, Sendable {
    case non_identification
    case impermanence
    case letting_be
    case softening
    case widening
    case compassionate_witnessing
}

struct LensSelection: Codable, Equatable, Sendable {
    var primary: CanonicalLens?
    var secondary: CanonicalLens?
}

struct LensSelector {
    // Mapping per spec with least-forceful priority
    private let mapping: [CanonicalPrimitive: (primary: CanonicalLens, secondary: CanonicalLens)] = [
        .identity_tightening: (.non_identification, .compassionate_witnessing),
        .narrative_looping: (.widening, .softening),
        .attachment_to_outcome: (.impermanence, .letting_be),
        .intolerance_of_uncertainty: (.letting_be, .softening),
        .self_judgement: (.compassionate_witnessing, .softening),
        .aversion_resistance: (.softening, .letting_be),
        .control_seeking: (.letting_be, .widening),
        .reassurance_seeking: (.compassionate_witnessing, .letting_be)
    ]

    func select(from dominant: [CanonicalPrimitive], background: [CanonicalPrimitive], topCandidateScore: Int?) -> LensSelection {
        // If confidence low (<70), choose a gentle universal lens.
        if let s = topCandidateScore, s < 70 {
            return LensSelection(primary: .softening, secondary: nil)
        }

        if let first = dominant.first, let m = mapping[first] {
            // Add secondary only if it softens/opens (by table design)
            return LensSelection(primary: m.primary, secondary: m.secondary)
        }

        if let firstBg = background.first, let m = mapping[firstBg] {
            return LensSelection(primary: m.primary, secondary: nil)
        }

        // Default gentle
        return LensSelection(primary: .softening, secondary: nil)
    }
}
