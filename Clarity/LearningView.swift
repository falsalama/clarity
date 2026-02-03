import SwiftUI

struct LearningView: View {
    @EnvironmentObject private var capsuleStore: CapsuleStore

    @State private var confirmClearLearned = false

    var body: some View {
        Form {
            Section {
                Text("Clarity can learn small cues from your captures to improve responses. This stays on this device unless you explicitly use Cloud Tap.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Learn from my captures", isOn: Binding(
                    get: { capsuleStore.capsule.learningEnabled },
                    set: { capsuleStore.setLearningEnabled($0) }
                ))

                Text("When on, Clarity may keep a compact, editable summary of patterns - for example how you prefer information presented.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Learning")
            }

            Section {
                Button(role: .destructive) {
                    confirmClearLearned = true
                } label: {
                    Text("Clear learned cues")
                }

                Text("This does not delete your captures. It only clears what Clarity has learnt from them.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Reset")
            }
        }
        .navigationTitle("Learning")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .confirmationDialog(
            "Clear learned cues?",
            isPresented: $confirmClearLearned,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                capsuleStore.clearLearnedTendencies()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the learned profile. You can keep using Capsule preferences.")
        }
    }
}

