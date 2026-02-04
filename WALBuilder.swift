import Foundation

struct WALBuilder {
    static func buildValidated(from redacted: String, now: Date = Date()) -> ValidatedWalSnapshot {
        let lift0 = Lift0Extractor().extract(from: redacted)
        let candidates = PrimitiveCandidateExtractor().extract(from: redacted)
        let topScore = candidates.first?.score
        let selection = PrimitiveCandidateExtractor().selectTop(from: candidates)
        let lenses = LensSelector().select(
            from: selection.dominant,
            background: selection.background,
            topCandidateScore: topScore
        )
        let validated = WALValidator().validate(
            lift0: lift0,
            primitiveDominant: selection.dominant,
            primitiveBackground: selection.background,
            candidates: candidates,
            lenses: lenses,
            confirmationNeeded: selection.needsConfirmation,
            now: now
        )
        return validated
    }
}
