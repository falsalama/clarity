// CapsuleLearningView.swift
import SwiftUI

struct CapsuleLearningView: View {
    @EnvironmentObject private var store: CapsuleStore

    var body: some View {
        List {
            Section {
                Text("Clarity can learn small patterns from your captures to improve responses. This stays on this device unless you explicitly use Cloud Tap.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Learning") {
                Toggle("Allow learning", isOn: Binding(
                    get: { store.capsule.learningEnabled },
                    set: { store.setLearningEnabled($0) }
                ))

                HStack {
                    Text("Learned items")
                    Spacer()
                    Text("\(store.capsule.learnedTendencies.count)")
                        .foregroundStyle(.secondary)
                }
            }

            if !store.capsule.learnedTendencies.isEmpty {
                Section("Learned patterns") {
                    ForEach(store.capsule.learnedTendencies) { t in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(t.statement)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 10) {
                                Text("Evidence \(t.evidenceCount)")
                                Text("Last \(t.lastSeenAt.formatted(date: .abbreviated, time: .omitted))")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        store.resetLearnedProfile()
                    } label: {
                        Text("Reset learned patterns")
                    }
                    .accessibilityHint("Clears learned patterns but keeps your preferences.")
                }
            }
        }
        .navigationTitle("Learning")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview {
    NavigationStack {
        CapsuleLearningView()
            .environmentObject(CapsuleStore())
    }
}

