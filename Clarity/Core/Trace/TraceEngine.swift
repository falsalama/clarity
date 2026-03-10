import Foundation
import SwiftData

@MainActor
enum TraceEngine {

    /// Builds and persists the validated turn trace (WAL), then optionally runs
    /// learning accumulation + capsule projection.
    ///
    /// Returns `true` only if learning was actually applied.
    @discardableResult
    static func processSavedTurn(
        turnID: UUID,
        redactedText: String,
        repo: TurnRepository,
        modelContext: ModelContext?,
        capsuleStore: CapsuleStore?,
        learningAllowed: Bool,
        now: Date = Date()
    ) throws -> Bool {
        let redacted = redactedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !redacted.isEmpty else { return false }

        let validated = WALBuilder.buildValidated(from: redacted, now: now)
        try repo.updateWAL(id: turnID, snapshot: validated)

        guard
            learningAllowed,
            let context = modelContext,
            let store = capsuleStore,
            store.capsule.learningEnabled
        else {
            return false
        }

        let learner = PatternLearner()
        let observations = learner.deriveObservations(from: validated, redactedText: redacted)
        try learner.apply(observations: observations, into: context, now: now)
        LearningSync.sync(context: context, capsuleStore: store, now: now)

        return true
    }
}
