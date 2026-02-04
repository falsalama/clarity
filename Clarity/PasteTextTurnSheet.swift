// PasteTextTurnSheet.swift
import SwiftUI
import SwiftData

/// Creates a new "text capture" Turn from pasted or typed text.
/// - Redaction-first: stores the redacted result as `transcriptRedactedActive`.
/// - Raw input is NOT stored (equivalent to `transcriptRaw` local-only, but here we choose nil).
struct PasteTextTurnSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dictionary: RedactionDictionary
    @EnvironmentObject private var capsuleStore: CapsuleStore

    @State private var text: String = ""
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false

    // Auto-focus keyboard
    @FocusState private var isEditorFocused: Bool

    let onCreated: (UUID) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $text)
                    .focused($isEditorFocused)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .textSelection(.enabled)
                    .frame(minHeight: 220)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .navigationTitle("Type text")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving…" : "Save") { save() }
                        .disabled(isSaving || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Delay focus slightly to ensure TextEditor is in hierarchy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isEditorFocused = true
                }
            }
        }
    }

    private func save() {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            errorMessage = "Text is empty."
            return
        }

        // Redaction-first (no raw paste stored)
        let redacted = Redactor(tokens: dictionary.tokens).redact(input).redactedText

        do {
            let repo = TurnRepository(context: modelContext)
            let id = try repo.createTextTurn(
                redactedText: redacted,
                recordedAt: Date(),
                captureContext: .unknown
            )

            // Local WAL build + learning (development flag, on-device only)
            if FeatureFlags.localWALBuildEnabled {
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
                    confirmationNeeded: selection.needsConfirmation
                )

                // Persist only the validated snapshot
                try repo.updateWAL(id: id, snapshot: validated)

                // Run learning if enabled
                if capsuleStore.capsule.learningEnabled {
                    let learner = PatternLearner()
                    let observations = learner.deriveObservations(from: validated, redactedText: redacted)
                    try learner.apply(observations: observations, into: modelContext, now: Date())

                    // Project PatternStats -> Capsule.learnedTendencies
                    LearningSync.sync(context: modelContext, capsuleStore: capsuleStore, now: Date())
                }
            }

            onCreated(id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
