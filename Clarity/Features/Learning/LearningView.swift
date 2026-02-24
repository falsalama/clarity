import SwiftUI
import SwiftData

struct LearningView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var capsuleStore: CapsuleStore

    @State private var confirmClearLearned = false
    @AppStorage("learning_show_debug_tags") private var showDebugTags = false

    var body: some View {
        Form {
            Section {
                Text("Clarity derives small cues from recent captures to improve responses. These cues decay over time and stay on this device unless you explicitly use Cloud Tap.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Learn from my captures", isOn: Binding(
                    get: { capsuleStore.capsule.learningEnabled },
                    set: { capsuleStore.setLearningEnabled($0) }
                ))
                Toggle("Show debug tags", isOn: $showDebugTags)

                HStack {
                    Text("Learned cues")
                    Spacer()
                    Text("\(capsuleStore.capsule.learnedTendencies.count)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Learning")
            }

            if !capsuleStore.capsule.learnedTendencies.isEmpty {
                Section {
                    ForEach(capsuleStore.capsule.learnedTendencies) { t in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.statement)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if showDebugTags {
                                    Text("\(t.sourceKindRaw ?? "—") • \(t.sourceKey ?? "—")")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .textSelection(.enabled)
                                }
                            }

                            VStack(alignment: .trailing) {
                                Text("x\(t.evidenceCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(t.lastSeenAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                    }
                } header: {
                    Text("Learned cues (derived)")
                } footer: {
                    Text("Derived cues are not identity statements. They summarise recent patterns and decay over time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    confirmClearLearned = true
                } label: {
                    Text("Clear learned cues")
                }

                Text("This does not delete your captures. It only clears the derived cues.")
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
        .onAppear {
            // Refresh projection from PatternStats -> Capsule (idempotent)
            LearningSync.sync(context: modelContext, capsuleStore: capsuleStore)
        }
        .alert(
            "Clear all learned cues?",
            isPresented: $confirmClearLearned
        ) {
            Button("Clear", role: .destructive) {
                // Hard reset: wipe stats from SwiftData, then clear projection/reset token
                LearningSync.wipeAllStats(context: modelContext)
                capsuleStore.clearLearnedTendencies()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all learned cues permanently.")
        }
    }
}
