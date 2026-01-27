// PasteTextTurnSheet.swift
import SwiftUI
import SwiftData

/// Creates a new "text capture" Turn from pasted text.
/// - Redaction-first: stores the redacted result as `transcriptRedactedActive`.
/// - Raw pasted input is NOT stored (equivalent to transcriptRaw local-only, but here we choose nil).
struct PasteTextTurnSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dictionary: RedactionDictionary

    @State private var text: String = ""
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false

    let onCreated: (UUID) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $text)
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
            .navigationTitle("Paste text")
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }

    private func save() {
        errorMessage = nil
        isSaving = true

        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            errorMessage = "Text is empty."
            isSaving = false
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
            onCreated(id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

